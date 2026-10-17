"""Smoke test for the harness: exhaustively checks smoke.v against a model."""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


async def _start(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    dut.a.value = 0
    dut.b.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0


@cocotb.test()
async def reset_clears_sum(dut):
    await _start(dut)
    dut.a.value = 5
    dut.b.value = 6
    await RisingEdge(dut.clk)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert int(dut.sum.value) == 0


@cocotb.test()
async def adds_all_operand_pairs(dut):
    await _start(dut)
    for a in range(16):
        for b in range(16):
            dut.a.value = a
            dut.b.value = b
            await RisingEdge(dut.clk)
            await RisingEdge(dut.clk)
            got = int(dut.sum.value)
            assert got == a + b, f"{a}+{b}: expected {a + b}, got {got}"
