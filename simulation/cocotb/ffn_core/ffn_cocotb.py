import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ReadOnly, Timer

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
