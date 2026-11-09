import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ReadOnly, Timer

"""
module requantizer(
    input clk100mhz,
    input rst_n,
    input signed [31:0] inp,
    input [1:0] layer,
    input start,
    output reg done,
    output reg signed [7:0] op
);
"""

PARAMETERS = {
    1: {
        "multiplier": 2039655736,
        "zero_point": -128,
        "right_shift": 7,
    },
    2: {
        "multiplier": 1561796795,
        "zero_point": -128,
        "right_shift": 6,
    },
    3: {
        "multiplier": 1630361836,
        "zero_point": 5,
        "right_shift": 5,
    },
}

DIRECTED_CASES = [
    # Basic zero-point behavior
    ("layer1_zero", 0, 1),
    ("layer2_zero", 0, 2),
    ("layer3_zero", 0, 3),

    # Small positive and negative values
    ("layer1_positive_one", 1, 1),
    ("layer1_negative_one", -1, 1),
    ("layer2_positive_one", 1, 2),
    ("layer2_negative_one", -1, 2),
    ("layer3_positive_one", 1, 3),
    ("layer3_negative_one", -1, 3),

    # Values useful for checking signed rounding
    ("layer1_positive_rounding", 582, 1),
    ("layer1_negative_rounding", -582, 1),
    ("layer2_positive_rounding", 582, 2),
    ("layer2_negative_rounding", -582, 2),
    ("layer3_positive_rounding", 582, 3),
    ("layer3_negative_rounding", -582, 3),

    # Larger normal operating values
    ("layer1_large_positive", 10000, 1),
    ("layer1_large_negative", -10000, 1),
    ("layer2_large_positive", 10000, 2),
    ("layer2_large_negative", -10000, 2),
    ("layer3_large_positive", 3000, 3),
    ("layer3_large_negative", -3000, 3),

    # Positive saturation
    ("layer1_positive_saturation", 100000, 1),
    ("layer2_positive_saturation", 100000, 2),
    ("layer3_positive_saturation", 100000, 3),

    # Negative saturation
    ("layer1_negative_saturation", -100000, 1),
    ("layer2_negative_saturation", -100000, 2),
    ("layer3_negative_saturation", -100000, 3),

    # Signed 32-bit input limits
    ("layer1_max_input", 2**31 - 1, 1),
    ("layer1_min_input", -(2**31), 1),
    ("layer2_max_input", 2**31 - 1, 2),
    ("layer2_min_input", -(2**31), 2),
    ("layer3_max_input", 2**31 - 1, 3),
    ("layer3_min_input", -(2**31), 3),
]

async def reset_dut(dut):
    await FallingEdge(dut.clk100mhz)
    dut.rst_n.value = 0
    dut.inp.value = 0
    dut.layer.value = 0
    dut.start.value = 0

    for _ in range(2):
        await RisingEdge(dut.clk100mhz)

    dut.rst_n.value = 1
    await FallingEdge(dut.clk100mhz)

async def run_requantizer(dut, name, inp, layer):
    await FallingEdge(dut.clk100mhz)
    dut.inp.value = inp
    dut.layer.value = layer
    dut.start.value = 1

    await FallingEdge(dut.clk100mhz)
    dut.start.value = 0

    for _ in range(20):
        await RisingEdge(dut.clk100mhz)
        await ReadOnly()
        if dut.done.value == 1:
            return dut.op.value.to_signed()

    raise AssertionError(f"{name}: timed out waiting for done")

def requantize_reference(inp, layer):
    if layer not in PARAMETERS:
        raise ValueError(f"Invalid layer: {layer}")

    if not -(2**31) <= inp <= 2**31 - 1:
        raise ValueError(f"Input is outside signed 32-bit range: {inp}")

    p = PARAMETERS[layer]
    multiplier = p["multiplier"]
    zero_point = p["zero_point"]
    right_shift = p["right_shift"]

    # EFFECTIVE_MULTIPLIER
    product = inp * multiplier

    # ROUNDING
    operand = (product + (1 << 30)) >> 31

    # DOUBLE_ROUNDING
    rounding_offset = 1 << (right_shift - 1)

    if operand >= 0:
        operand = (operand + rounding_offset) >> right_shift
    else:
        operand = (operand + rounding_offset - 1) >> right_shift

    # ZERO_POINT
    operand += zero_point

    # SATURATION
    operand = max(-128, min(127, operand))

    return operand

@cocotb.test()
async def test_directed_cases(dut):
    cocotb.start_soon(Clock(dut.clk100mhz, 10, unit="ns").start(start_high=False))

    await reset_dut(dut)

    for name, inp, layer in DIRECTED_CASES:
        expected = requantize_reference(inp, layer)
        actual = await run_requantizer(dut, name, inp, layer)

        assert actual == expected, (
            f"{name}: "
            f"input={inp}, "
            f"layer={layer}, "
            f"expected={expected}, "
            f"actual={actual}"
        )

@cocotb.test()
async def test_randomized(dut):
    cocotb.start_soon(Clock(dut.clk100mhz, 10, unit="ns").start(start_high=False))

    await reset_dut(dut)

    rng = random.Random(1234)

    for test_number in range(1000):
        inp = rng.randint(-(2**31), 2**31 - 1)
        layer = (test_number % 3) + 1

        expected = requantize_reference(inp, layer)
        actual = await run_requantizer(
            dut,
            f"random_{test_number}",
            inp,
            layer,
        )

        assert actual == expected, (
            f"random_{test_number}: "
            f"input={inp}, "
            f"layer={layer}, "
            f"expected={expected}, "
            f"actual={actual}"
        )

@cocotb.test()
async def test_reset(dut):
    cocotb.start_soon(Clock(dut.clk100mhz, 10, unit="ns").start(start_high=False))

    dut.rst_n.value = 0
    dut.inp.value = 0
    dut.layer.value = 0
    dut.start.value = 0

    await Timer(1, "ns")
    assert dut.done.value == 0, f"done={dut.done.value} during reset"
    assert dut.op.value.to_signed() == 0, f"result={dut.op.value} during reset"

    for _ in range (8):
        await FallingEdge(dut.clk100mhz)
        await Timer(1, "ns")

        assert dut.done.value == 0, f"done={dut.done.value} during reset"
        assert dut.op.value.to_signed() == 0, f"result={dut.op.value} during reset"

    dut.rst_n.value = 1
    await RisingEdge(dut.clk100mhz)
    await ReadOnly()

    assert dut.done.value == 0
    assert dut.op.value.to_signed() == 0

@cocotb.test()
async def test_reset_mid_operation(dut):
    cocotb.start_soon(Clock(dut.clk100mhz, 10, unit="ns").start(start_high=False))
    await reset_dut(dut)

    name, inp, layer = DIRECTED_CASES[0]
    expected = requantize_reference(inp, layer)

    await FallingEdge(dut.clk100mhz)
    dut.inp.value = inp
    dut.layer.value = layer
    dut.start.value = 1
    
    await FallingEdge(dut.clk100mhz)
    dut.start.value = 0

    await FallingEdge(dut.clk100mhz)
    assert dut.done.value == 0, "operation finished before reset; test is not mid-operation"

    dut.rst_n.value = 0
    await Timer(1, "ns")
    assert dut.done.value == 0, f"done={dut.done.value} after asynchronous reset"
    assert dut.op.value.to_signed() == 0, f"result={dut.op.value} after asynchronous reset"

    await FallingEdge(dut.clk100mhz)
    dut.rst_n.value = 1

    for _ in range(10):
        await FallingEdge(dut.clk100mhz)
        assert dut.done.value == 0, f"done={dut.done.value} after reset"
        assert dut.op.value.to_signed() == 0, f"result={dut.op.value} after reset"

    actual = await run_requantizer(dut, name, inp, layer)
    assert actual == expected, f"{name}: expected {expected}, got {actual}"