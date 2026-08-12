# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

"""
Testbench for the standalone vga_hvsync_generator module.
Tests VGA timing, sync signal behavior, and pixel counters directly
on the hvsync_generator submodule (no Tiny Tapeout wrapper).

Signal mapping matches the actual RTL:
    hpos, vpos    -> horizontal/vertical pixel position counters
    display_on    -> combinational "visible frame" flag
    hsync, vsync  -> registered sync pulses
    reset_n       -> active-low synchronous reset
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge


# VGA timing constants (from vga_hvsync_generator.v)
H_DISPLAY = 640
H_BACK = 48
H_FRONT = 16
H_SYNC = 96
H_MAX = H_DISPLAY + H_BACK + H_FRONT + H_SYNC - 1  # 799

V_DISPLAY = 480
V_TOP = 33
V_BOTTOM = 10
V_SYNC = 2
V_MAX = V_DISPLAY + V_TOP + V_BOTTOM + V_SYNC - 1  # 524

H_SYNC_START = H_DISPLAY + H_FRONT  # 656
H_SYNC_END = H_SYNC_START + H_SYNC - 1  # 751

V_SYNC_START = V_DISPLAY + V_BOTTOM  # 490
V_SYNC_END = V_SYNC_START + V_SYNC - 1  # 491


async def reset_dut(dut):
    """Reset the DUT and start clock. reset_n is active-low: hold it
    at 0 to assert reset, then release it to 1 to begin normal operation."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.reset_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.reset_n.value = 1
    await ClockCycles(dut.clk, 1)


async def step(dut, cycles=1):
    """Step forward N clock cycles."""
    for _ in range(cycles):
        await RisingEdge(dut.clk)
        await ReadOnly()


@cocotb.test()
async def test_reset_behavior(dut):
    """Test that reset properly initializes the module."""
    dut._log.info("=== TEST: Reset Behavior ===")
    await reset_dut(dut)
    await ReadOnly()

    assert int(dut.hpos.value) == 1, f"Expected hpos=1, got {int(dut.hpos.value)}"
    assert int(dut.vpos.value) == 0, f"Expected vpos=0, got {int(dut.vpos.value)}"
    assert int(dut.display_on.value) == 1, "Display should be active at startup"
    assert int(dut.hsync.value) == 1, "hsync should be 1 (not in sync pulse)"
    assert int(dut.vsync.value) == 1, "vsync should be 1 (not in sync pulse)"

    dut._log.info("✓ Reset behavior correct")


@cocotb.test()
async def test_horizontal_timing(dut):
    """Test horizontal pixel counter and hsync pulse timing, including wrap-around."""
    dut._log.info("=== TEST: Horizontal Timing ===")
    await reset_dut(dut)
    await ReadOnly()

    # Test visible display region
    dut._log.info(f"Checking visible region (0-{H_DISPLAY-1})")
    for x in range(1, H_DISPLAY):
        assert int(dut.hpos.value) == x, f"At step {x-1}: hpos mismatch"
        assert int(dut.display_on.value) == 1, f"At hpos={x}: display should be active"
        await step(dut)

    # Test front porch (visible end)
    assert int(dut.hpos.value) == H_DISPLAY, "hpos should be at H_DISPLAY"
    assert int(dut.display_on.value) == 0, "Display should be inactive in front porch"
    dut._log.info(f"✓ Front porch: display_on goes inactive at hpos={H_DISPLAY}")

    # Test hsync pulse
    await step(dut, H_SYNC_START - H_DISPLAY)
    assert int(dut.hpos.value) == H_SYNC_START, "Should reach hsync start"
    assert int(dut.hsync.value) == 1, "hsync should still be 1 before pulse"

    await step(dut)
    assert int(dut.hpos.value) == H_SYNC_START + 1
    assert int(dut.hsync.value) == 0, "hsync should be 0 during pulse"
    dut._log.info(f"✓ hsync pulse starts at hpos={H_SYNC_START}")

    await step(dut, H_SYNC_END - H_SYNC_START)
    assert int(dut.hpos.value) == H_SYNC_END + 1
    assert int(dut.hsync.value) == 0, "hsync should still be 0"

    await step(dut)
    assert int(dut.hpos.value) == H_SYNC_END + 2
    assert int(dut.hsync.value) == 1, "hsync should return to 1"
    dut._log.info(f"✓ hsync pulse ends at hpos={H_SYNC_END+1}")

    # Test line end and wrap-around into next line
    await step(dut, H_MAX - (H_SYNC_END + 2) + 1)
    assert int(dut.hpos.value) == 0, "hpos should wrap to 0"
    assert int(dut.vpos.value) == 1, "vpos should increment to 1"
    assert int(dut.display_on.value) == 1, "Display should be active again on new line"
    assert int(dut.hsync.value) == 1, "hsync should be 1 after wrap"
    assert int(dut.vsync.value) == 1, "vsync should still be 1 (not near frame end)"
    dut._log.info(f"✓ Horizontal counter wraps at hpos={H_MAX+1}")


@cocotb.test()
async def test_full_frame_cycle(dut):
    """Test a complete frame from start to start of next frame."""
    dut._log.info("=== TEST: Full Frame Cycle ===")
    await reset_dut(dut)

    # Calculate total pixels in one frame
    pixels_per_line = H_MAX + 1
    total_lines = V_MAX + 1
    total_pixels = pixels_per_line * total_lines

    dut._log.info(f"Frame size: {H_DISPLAY}x{V_DISPLAY} pixels")
    dut._log.info(f"Total timing: {pixels_per_line}x{total_lines} ({total_pixels} pixels)")

    # Quick check: after one frame, we should be back at (0, 0)
    await step(dut, total_pixels - 1)

    hpos = int(dut.hpos.value)
    vpos = int(dut.vpos.value)
    display_on = int(dut.display_on.value)

    assert hpos == 0, f"After frame cycle, hpos should be 0, got {hpos}"
    assert vpos == 0, f"After frame cycle, vpos should be 0, got {vpos}"
    assert display_on == 1, f"After frame cycle, display_on should be 1, got {display_on}"

    dut._log.info(f"✓ Frame cycle complete: {total_pixels} pixels")
    dut._log.info(f"  Horizontal: {pixels_per_line} pixels/line")
    dut._log.info(f"  Vertical: {total_lines} lines/frame")