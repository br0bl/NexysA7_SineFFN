import cocotb
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

@cocotb.test()
async def test_reset(dut):
    cocotb.start_soon(Clock(dut.clk100mhz, 10, unit="ns").start(start_high=False))

    dut.rst_n.value = 0
    dut.inp.value = 0
    dut.layer.value = 0
    dut.start.value = 0

    await Timer(1, "ns")
    assert dut.done.value == 0, f"done={dut.done.value} during reset"
    assert dut.op.value == 0, f"result={dut.op.value} during reset"

    for _ in range (8):
        await FallingEdge(dut.clk100mhz)
        await Timer(1, "ns")

        assert dut.done.value == 0, f"done={dut.done.value} during reset"
        assert dut.op.value == 0, f"result={dut.op.value} during reset"

    dut.rst_n.value = 1
    await RisingEdge(dut.clk100mhz)
    await ReadOnly()

    assert dut.done.value == 0
    assert dut.op.value == 0