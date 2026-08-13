# SPDX-FileCopyrightText: (c) 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

"""
Testbench for the top-level `vga` module.

Drives the `vga` module for several full frames while acting as its
external cell memory: every cycle it reads the address the DUT is
asking for (col_idx, row_idx) and drives `cell_memory` with the value
looked up from a simple Python grid (MEMORY below).

This test does not produce any image file. Run with WAVES=1 to get an
.fst trace, then inspect/visualize it with a waveform viewer or a tool
like tt-vgaviz.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, ReadOnly, RisingEdge

# ---------------------------------------------------------------------------
# VGA timing constants (must match vga_hvsync_generator.sv)
# ---------------------------------------------------------------------------
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

PIXELS_PER_LINE = H_MAX + 1
LINES_PER_FRAME = V_MAX + 1
PIXELS_PER_FRAME = PIXELS_PER_LINE * LINES_PER_FRAME

NUM_FRAMES = 5

# ---------------------------------------------------------------------------
# Grid parameters (must match the `vga` module's NUM_COLS / NUM_ROWS)
# ---------------------------------------------------------------------------
NUM_COLS = 16
NUM_ROWS = 12

# ---------------------------------------------------------------------------
# "Memory" model -- edit this to change what is displayed.
#
# MEMORY[row][col] -> 0 (dead) or 1 (alive)
#
# By default this builds a checkerboard, but you can replace the
# generator below with any pattern you like, e.g. a fixed 2D list:
#
#   MEMORY = [
#       [0, 1, 0, 1, ...],
#       [1, 0, 1, 0, ...],
#       ...
#   ]
# ---------------------------------------------------------------------------
MEMORY = [
    [(col + row) % 2 for col in range(NUM_COLS)]
    for row in range(NUM_ROWS)
]


def read_memory(col, row):
    """Emulates reading external cell memory at address (col, row)."""
    if 0 <= row < NUM_ROWS and 0 <= col < NUM_COLS:
        return MEMORY[row][col]
    return 0


# Standard VGA pixel clock: 25.175 MHz -> period ~= 39.7219 ns
CLOCK_FREQ_HZ = 25_175_000
CLOCK_PERIOD_NS = 39.72


async def reset_dut(dut):
    """Start the clock (25.175 MHz VGA pixel clock) and reset the DUT.
    reset_n is active-low."""
    clock = Clock(dut.clk, CLOCK_PERIOD_NS, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.simulation_running.value = 1
    dut.cursorpos.value = 0
    dut.cell_memory.value = 0

    dut.reset_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.reset_n.value = 1
    await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_vga_screen(dut):
    """Drive the `vga` module for NUM_FRAMES frames, feeding it the
    pattern defined in MEMORY through cell_memory. Produces an .fst
    trace only (when run with WAVES=1); no image file is written."""
    dut._log.info("=== TEST: VGA Screen (%d frames) ===" % NUM_FRAMES)
    await reset_dut(dut)

    total_cycles = PIXELS_PER_FRAME * NUM_FRAMES
    dut._log.info(
        "Simulating %dx%d, %d frame(s), %d total cycles"
        % (H_DISPLAY, V_DISPLAY, NUM_FRAMES, total_cycles)
    )

    for _ in range(total_cycles):
        await RisingEdge(dut.clk)

        # Normal phase: reading current address and writing the
        # corresponding memory value back is safe here, since
        # col_idx/row_idx/cell_memory/cell_type/RGB are all purely
        # combinational (see vga_get_cell_idx / vga_get_cell_type /
        # vga_get_pixel_color).
        col = int(dut.col_idx.value)
        row = int(dut.row_idx.value)
        dut.cell_memory.value = read_memory(col, row)

        await ReadOnly()

    dut._log.info("Simulation complete, %d frame(s) generated" % NUM_FRAMES)