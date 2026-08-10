# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

"""
Comprehensive testbench for VGA module.
Tests VGA timing, output mapping, and control signals.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge


# VGA timing constants (from hvsync_generator.sv)
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
    """Reset the DUT and start clock."""
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.reset_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.reset_n.value = 1
    await ClockCycles(dut.clk, 1)


async def step(dut, cycles=1):
    """Step forward N clock cycles."""
    for _ in range(cycles):
        await RisingEdge(dut.clk)
        await ReadOnly()


def uut(dut):
    """Get reference to user project (vga module)."""
    return dut.user_project


def bit(value, index):
    """Extract bit at index from value."""
    return int(value[index])


@cocotb.test()
async def test_reset_behavior(dut):
    """Test that reset properly initializes the module."""
    dut._log.info("=== TEST: Reset Behavior ===")
    await reset_dut(dut)
    await ReadOnly()

    project = uut(dut)

    # After reset, we should be at pixel (1, 0) with valid video signal
    assert int(project.pix_x.value) == 1, f"Expected pix_x=1, got {int(project.pix_x.value)}"
    assert int(project.pix_y.value) == 0, f"Expected pix_y=0, got {int(project.pix_y.value)}"
    assert int(project.video_active.value) == 1, "Video should be active at startup"
    assert int(project.hsync.value) == 1, "hsync should be 1 (not in sync pulse)"
    assert int(project.vsync.value) == 1, "vsync should be 1 (not in sync pulse)"
    assert int(project.uio_out.value) == 0, "Unused outputs should be 0"
    assert int(project.uio_oe.value) == 0, "Unused outputs should be disabled"

    dut._log.info("✓ Reset behavior correct")


@cocotb.test()
async def test_horizontal_timing(dut):
    """Test horizontal pixel counter and hsync pulse timing."""
    dut._log.info("=== TEST: Horizontal Timing ===")
    await reset_dut(dut)
    await ReadOnly()

    project = uut(dut)

    # Test visible display region
    dut._log.info(f"Checking visible region (0-{H_DISPLAY-1})")
    for x in range(1, H_DISPLAY):
        assert int(project.pix_x.value) == x, f"At step {x-1}: pix_x mismatch"
        assert int(project.video_active.value) == 1, f"At x={x}: video should be active"
        await step(dut)

    # Test front porch (visible end)
    assert int(project.pix_x.value) == H_DISPLAY, "Pixel should be at H_DISPLAY"
    assert int(project.video_active.value) == 0, "Video should be inactive in front porch"
    dut._log.info(f"✓ Front porch: video_active goes inactive at x={H_DISPLAY}")

    # Test hsync pulse
    await step(dut, H_SYNC_START - H_DISPLAY)
    assert int(project.pix_x.value) == H_SYNC_START, "Should reach hsync start"
    assert int(project.hsync.value) == 1, "hsync should still be 1 before pulse"

    await step(dut)
    assert int(project.hsync.value) == 0, "hsync should be 0 during pulse"
    dut._log.info(f"✓ hsync pulse starts at x={H_SYNC_START}")

    await step(dut, H_SYNC_END - H_SYNC_START)
    assert int(project.hsync.value) == 0, "hsync should still be 0"

    await step(dut)
    assert int(project.hsync.value) == 1, "hsync should return to 1"
    dut._log.info(f"✓ hsync pulse ends at x={H_SYNC_END+1}")

    # Test line end and wrap-around
    await step(dut, H_MAX - (H_SYNC_END + 2) + 1)
    assert int(project.pix_x.value) == 0, "pix_x should wrap to 0"
    dut._log.info(f"✓ Horizontal counter wraps at x={H_MAX+1}")


@cocotb.test()
async def test_unused_outputs(dut):
    """Test that unused outputs are properly disabled."""
    dut._log.info("=== TEST: Unused Outputs ===")
    await reset_dut(dut)
    await ReadOnly()

    project = uut(dut)

    # Check that bidir outputs are all disabled (output enable should be 0)
    assert int(project.uio_oe.value) == 0, "uio_oe should be 0 (outputs disabled)"
    assert int(project.uio_out.value) == 0, "uio_out should be 0"

    dut._log.info("✓ Bidir outputs properly disabled")


@cocotb.test()
async def test_full_frame_cycle(dut):
    """Test a complete frame from start to start of next frame."""
    dut._log.info("=== TEST: Full Frame Cycle ===")
    await reset_dut(dut)

    project = uut(dut)

    # Calculate total pixels in one frame
    pixels_per_line = H_MAX + 1
    total_lines = V_MAX + 1
    total_pixels = pixels_per_line * total_lines

    dut._log.info(f"Frame size: {H_DISPLAY}x{V_DISPLAY} pixels")
    dut._log.info(f"Total timing: {pixels_per_line}x{total_lines} ({total_pixels} pixels)")

    # Quick check: after one frame, we should be back at (0, 0)
    await step(dut, total_pixels - 1)

    pix_x = int(project.pix_x.value)
    pix_y = int(project.pix_y.value)
    video_active = int(project.video_active.value)

    assert pix_x == 0, f"After frame cycle, pix_x should be 0, got {pix_x}"
    assert pix_y == 0, f"After frame cycle, pix_y should be 0, got {pix_y}"
    assert video_active == 1, f"After frame cycle, video_active should be 1, got {video_active}"

    dut._log.info(f"✓ Frame cycle complete: {total_pixels} pixels")
    dut._log.info(f"  Horizontal: {pixels_per_line} pixels/line")
    dut._log.info(f"  Vertical: {total_lines} lines/frame")

