# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge


H_DISPLAY = 640
H_BACK = 48
H_FRONT = 16
H_SYNC = 96
H_MAX = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1
H_SYNC_START = H_DISPLAY + H_FRONT
H_SYNC_END = H_SYNC_START + H_SYNC - 1


async def reset_dut(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)


async def step(dut, cycles=1):
    for _ in range(cycles):
        await RisingEdge(dut.clk)
        await ReadOnly()


def uut(dut):
    return dut.user_project


def bit(value, index):
    return int(value[index])


@cocotb.test()
async def test_vga_sync_timing(dut):
    await reset_dut(dut)
    await ReadOnly()

    project = uut(dut)

    assert int(project.pix_x.value) == 1
    assert int(project.pix_y.value) == 0
    assert int(project.video_active.value) == 1
    assert int(project.hsync.value) == 1
    assert int(project.vsync.value) == 1
    assert bit(project.uo_out.value, 7) == int(project.hsync.value)
    assert bit(project.uo_out.value, 3) == int(project.vsync.value)
    assert int(project.uio_out.value) == 0
    assert int(project.uio_oe.value) == 0

    await step(dut, H_DISPLAY - 1)
    assert int(project.pix_x.value) == H_DISPLAY
    assert int(project.video_active.value) == 0

    await step(dut, H_SYNC_START - H_DISPLAY)
    assert int(project.pix_x.value) == H_SYNC_START
    assert int(project.hsync.value) == 1

    await step(dut)
    assert int(project.pix_x.value) == H_SYNC_START + 1
    assert int(project.hsync.value) == 0

    await step(dut, H_SYNC_END - H_SYNC_START)
    assert int(project.pix_x.value) == H_SYNC_END + 1
    assert int(project.hsync.value) == 0

    await step(dut)
    assert int(project.pix_x.value) == H_SYNC_END + 2
    assert int(project.hsync.value) == 1

    await step(dut, H_MAX - (H_SYNC_END + 2) + 1)
    assert int(project.pix_x.value) == 0
    assert int(project.pix_y.value) == 1
    assert int(project.video_active.value) == 1
    assert int(project.hsync.value) == 1
    assert int(project.vsync.value) == 1


@cocotb.test()
async def test_vga_output_pin_mapping(dut):
    await reset_dut(dut)

    project = uut(dut)

    assert bit(project.uo_out.value, 7) == int(project.hsync.value)
    assert bit(project.uo_out.value, 3) == int(project.vsync.value)
    assert int(project.uio_out.value) == 0
    assert int(project.uio_oe.value) == 0