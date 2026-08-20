# SPDX-FileCopyrightText: (c) 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

"""
Testbench for the top-level `vga` module using cocotb_vga.

Drives the `vga` module while acting as its external cell memory: on
every cycle it reads the address the DUT asks for (col_idx, row_idx)
and drives `cell_memory` with a value looked up from a Python "memory"
model (see PATTERNS / read_memory below). cocotb_vga captures the
resulting VGA output (via uo_out) into PNG frames and an animated GIF.

The memory-driving loop runs as an independent background task so it
never blocks on cocotb_vga's internal state -- capture completion is
determined solely by cap.wait_for_frames(), not by polling any
private/internal attribute of VGACapture.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly
from cocotb_vga import VGACapture, TinyVGA, VGA_640x480_60

# ---------------------------------------------------------------------------
# Grid parameters (must match the `vga` module's NUM_COLS / NUM_ROWS)
# ---------------------------------------------------------------------------
NUM_COLS = 16
NUM_ROWS = 12
LINE_SPACING = 4
LINE_WIDTH = 1

# ---------------------------------------------------------------------------
# Timing / capture parameters
# ---------------------------------------------------------------------------
# Standard VGA pixel clock: 25.175 MHz -> period ~= 39.7219 ns
CLOCK_PERIOD_NS = 39.722

NUM_FRAMES = 5

# 800 x 525 total cycles per frame (640x480 active + blanking)
PIXELS_PER_LINE = 800
LINES_PER_FRAME = 525
PIXELS_PER_FRAME = PIXELS_PER_LINE * LINES_PER_FRAME


# ---------------------------------------------------------------------------
# "Memory" model -- edit this to change what is displayed.
#
# read_memory(col, row, frame) is called for every pixel address the DUT
# asks for, and must return 0 (dead) or 1 (alive) for that cell on the
# given frame number (0-indexed).
#
# This version shows a DIFFERENT, distinct pattern on every frame,
# cycling through a small list of patterns. Add/remove/edit entries in
# PATTERNS to change what each frame looks like.
# ---------------------------------------------------------------------------


def pattern_all_dead(col, row):
    return 0


def pattern_all_alive(col, row):
    return 1


def pattern_checkerboard(col, row):
    return (col + row) % 2


def pattern_vertical_lines(col, row):
    return 1 if col % LINE_SPACING == 0 else 0


def pattern_horizontal_lines(col, row):
    return 1 if row % 3 == 0 else 0


def pattern_border(col, row):
    on_edge = col == 0 or col == NUM_COLS - 1 or row == 0 or row == NUM_ROWS - 1
    return 1 if on_edge else 0


def pattern_diagonal(col, row):
    return 1 if (col - row) % NUM_COLS == 0 else 0


def pattern_center_block(col, row):
    cx, cy = NUM_COLS // 2, NUM_ROWS // 2
    return 1 if (cx - 2 <= col <= cx + 1 and cy - 2 <= row <= cy + 1) else 0


# One pattern function per frame, in order. read_memory() cycles through
# this list using (frame % len(PATTERNS)), so it also works if NUM_FRAMES
# is larger than the number of patterns defined here.
PATTERNS = [
    pattern_all_dead,
    pattern_checkerboard,
    pattern_vertical_lines,
    pattern_horizontal_lines,
    pattern_border,
    pattern_diagonal,
    pattern_center_block,
    pattern_all_alive,
]


def read_memory(col, row, frame):
    """Emulates reading external cell memory at address (col, row) for
    the given frame number. Selects a different pattern function per
    frame from PATTERNS, cycling if there are more frames than
    patterns."""
    if not (0 <= row < NUM_ROWS and 0 <= col < NUM_COLS):
        return 0
    pattern_fn = PATTERNS[frame % len(PATTERNS)]
    return pattern_fn(col, row)


async def reset_dut(dut):
    """Reset the DUT. reset_n is active-low."""
    dut.reset_n.value = 0
    dut.running.value = 1
    dut.cursorpos.value = 0
    dut.cell_memory.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.reset_n.value = 1
    await RisingEdge(dut.clk)


async def drive_memory(dut):
    """Runs forever in the background, driving cell_memory based on
    the current pixel address and frame number. The frame number is
    tracked locally by counting elapsed cycles, since VGACapture's
    internal frame count is not something this loop reads from."""
    cycle = 0
    while True:
        await RisingEdge(dut.clk)

        frame = cycle // PIXELS_PER_FRAME
        col = int(dut.col_idx.value)
        row = int(dut.row_idx.value)
        dut.cell_memory.value = read_memory(col, row, frame)

        await ReadOnly()
        cycle += 1


@cocotb.test()
async def test_vga_screen(dut):
    """Capture NUM_FRAMES frames of VGA output from the `vga` module
    using cocotb_vga, while continuously feeding it a per-frame
    pattern through cell_memory."""
    cocotb.start_soon(Clock(dut.clk, CLOCK_PERIOD_NS, unit="ns").start())
    await reset_dut(dut)

    driver_task = cocotb.start_soon(drive_memory(dut))

    cap = VGACapture(
        dut.clk,
        TinyVGA(dut.uo_out),
        VGA_640x480_60,
        out_dir="output",
        name="vga_screen",
    ).start()

    frames = await cap.wait_for_frames(NUM_FRAMES)
    cap.stop()
    driver_task.kill()

    cap.check_timing(require_frames=NUM_FRAMES)
    cap.save_gif()
