import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ReadOnly, Timer

import numpy as np
from pathlib import Path

from reference import get_tflite_prediction, get_tflite_tensors

"""
module ffn_core(
                            input clk100mhz,
                            input rst_n,
                            input start,
                            input signed [7:0] x_q,
                            output reg busy,
                            output reg done,
                            output reg signed [7:0] y_q
                     );
"""

MODEL_PATH = Path(__file__).resolve().parent / "hello_world_int8.tflite"

async def reset_dut(dut):
    await FallingEdge(dut.clk100mhz)
    dut.rst_n.value = 0
    dut.start.value = 0
    dut.x_q.value = 0

    await FallingEdge(dut.clk100mhz)
    dut.rst_n.value = 1
    await FallingEdge(dut.clk100mhz)

async def run_ffn(dut, x):
    await FallingEdge(dut.clk100mhz)
    dut.start.value = 1
    dut.x_q.value = x

    await FallingEdge(dut.clk100mhz)
    dut.start.value = 0

    for _ in range(2000):
        await FallingEdge(dut.clk100mhz)
        await ReadOnly()

        if dut.done.value == 1:
            return dut.y_q.value.to_signed()

    raise AssertionError(f"{x}: timed out waiting for done")

@cocotb.test()
async def test_reset(dut):
    cocotb.start_soon(Clock(dut.clk100mhz, 10, unit="ns").start(start_high=False))

    dut.rst_n.value = 0
    dut.start.value = 0
    dut.x_q.value = 0   

    await Timer(1, "ns")
    assert dut.done.value == 0, f"done={dut.done.value} during reset"
    assert dut.busy.value == 0, f"busy={dut.busy.value} during reset"
    assert dut.y_q.value.to_signed() == 0, f"result={dut.y_q.value} during reset"

    for _ in range (12):
        await FallingEdge(dut.clk100mhz)

        assert dut.done.value == 0, f"done={dut.done.value} during reset"
        assert dut.busy.value == 0, f"busy={dut.busy.value} during reset"
        assert dut.y_q.value.to_signed() == 0, f"result={dut.y_q.value} during reset"

    dut.rst_n.value = 1

    await RisingEdge(dut.clk100mhz)
    await Timer(1, "ns")

    assert dut.done.value == 0, f"done={dut.done.value} after reset"
    assert dut.busy.value == 0, f"busy={dut.busy.value} after reset"
    assert dut.y_q.value.to_signed() == 0, f"result={dut.y_q.value} after reset"

    await FallingEdge(dut.clk100mhz)

@cocotb.test()
async def test_ffn(dut):
    cocotb.start_soon(Clock(dut.clk100mhz, 10, unit="ns").start(start_high=False))
    await reset_dut(dut)

    x_values = np.arange(-128, 128, dtype=np.int8)

    y_actual = get_tflite_prediction(MODEL_PATH, x_values)

    mismatch_count = 0

    for x, expected in zip(x_values, y_actual):
        observed = await run_ffn(dut, int(x))

        if(observed != int(expected)):
            mismatch_count += 1
            dut._log.error(f"x={int(x)}: received={observed}, expected={int(expected)}")
            
    assert mismatch_count == 0, f"{mismatch_count} mismatches detected"

@cocotb.test()
async def test_activations(dut):
    cocotb.start_soon(Clock(dut.clk100mhz, 10, unit="ns").start(start_high=False))
    await reset_dut(dut)

    layer1_name = "sequential/dense/MatMul;sequential/dense/Relu;sequential/dense/BiasAdd"
    layer2_name = "sequential/dense_1/MatMul;sequential/dense_1/Relu;sequential/dense_1/BiasAdd"
    output_name = "StatefulPartitionedCall:0"

    mismatch_count = 0

    for x in range(-128, 128):
        tensors = get_tflite_tensors(MODEL_PATH, x)

        expected_layer1 = tensors[layer1_name].reshape(-1).tolist()
        expected_layer2 = tensors[layer2_name].reshape(-1).tolist()
        expected_output = int(tensors[output_name].reshape(-1)[0])

        observed_output = await run_ffn(dut, x)

        rtl_layer1 = [dut.layer1_activations[i].value.to_signed() for i in range(16)]
        rtl_layer2 = [dut.layer2_activations[i].value.to_signed() for i in range(16)]

        layers = [
            ("layer 1", rtl_layer1, expected_layer1),
            ("layer 2", rtl_layer2, expected_layer2),
        ]

        for name, observed, expected in layers:
            differences = [
                (i, received, reference)
                for i, (received, reference) in enumerate(zip(observed, expected))
                if received != reference
            ]

            if differences:
                mismatch_count += 1
                dut._log.error(f"x={x}: {name} differences (neuron, received, expected)={differences}")

        if observed_output != expected_output:
            mismatch_count += 1
            dut._log.error(f"x={x}: output received={observed_output}, expected={expected_output}")

    assert mismatch_count == 0, f"{mismatch_count} tensor comparisons failed"
    dut._log.info("Both hidden layers and final output match TFLite for all 256 inputs")
