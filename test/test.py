"""
Button bit mapping in ui_in (from the original SV comment):
  ui_in[0] = up
  ui_in[1] = down
  ui_in[2] = left
  ui_in[3] = right
  ui_in[4] = set
  ui_in[5] = start
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb_vga import VGACapture, TinyVGA, VGA_640x480_60

# Bit positions for readability
UP, DOWN, LEFT, RIGHT, SET, START = 0, 1, 2, 3, 4, 5

# Number of frames to simulate
NUM_FRAMES = 10

async def reset(dut):
    dut.ui_in.value = 0
    dut.reset_n.value = 0
    dut.ena.value = 1
    await Timer(100, unit="ns")
    dut.reset_n.value = 1
    await Timer(100, unit="ns")


def set_bit(dut, bit, value):
    """Set/clear a single bit of ui_in without disturbing the others."""
    cur = int(dut.ui_in.value)
    if value:
        cur |= (1 << bit)
    else:
        cur &= ~(1 << bit)
    dut.ui_in.value = cur


@cocotb.test()
async def test_project(dut):
    # Clock that matches VGA
    clock = Clock(dut.clk, 39.722, unit="ns")
    cocotb.start_soon(clock.start())

    await reset(dut)

    cap = VGACapture(
        dut.clk, TinyVGA(dut.uo_out), VGA_640x480_60,
        out_dir="output", name="vga_screen"
    ).start()

    # Move cursor to (1,1)
    set_bit(dut, DOWN, 1)
    set_bit(dut, RIGHT, 1)
    await Timer(400, unit="ns")

    # Write (set) cell at (1,1)
    set_bit(dut, DOWN, 0)
    set_bit(dut, RIGHT, 0)
    set_bit(dut, SET, 1)
    await Timer(400, unit="ns")

    # Move to (2,1)
    set_bit(dut, SET, 0)
    set_bit(dut, RIGHT, 1)
    await Timer(400, unit="ns")

    # Move to (3,2)
    set_bit(dut, DOWN, 1)
    set_bit(dut, RIGHT, 1)
    await Timer(400, unit="ns")

    # Write (set) cell at (3,2)
    set_bit(dut, DOWN, 0)
    set_bit(dut, RIGHT, 0)
    set_bit(dut, SET, 1)
    await Timer(400, unit="ns")

    set_bit(dut, DOWN, 1)
    set_bit(dut, RIGHT, 1)
    await Timer(400, unit="ns")

    # Move to (4,3)
    set_bit(dut, DOWN, 0)
    set_bit(dut, RIGHT, 0)
    await Timer(400, unit="ns")

    # Move (up+right again)
    set_bit(dut, DOWN, 1)
    set_bit(dut, RIGHT, 1)
    await Timer(400, unit="ns")

    # Move to (5,4), then start moving left
    set_bit(dut, DOWN, 0)
    set_bit(dut, RIGHT, 0)
    set_bit(dut, LEFT, 1)
    await Timer(400, unit="ns")

    # Move to (5,3), start moving right again
    set_bit(dut, LEFT, 0)
    set_bit(dut, RIGHT, 1)
    await Timer(400, unit="ns")

    # Move to (6,3), write (set) cell there
    set_bit(dut, RIGHT, 0)
    set_bit(dut, SET, 1)
    await Timer(400, unit="ns")

    # Press start to begin the simulation
    set_bit(dut, START, 1)
    set_bit(dut, SET, 0)
    await Timer(400, unit="ns")

    # Release start (simulation running)
    set_bit(dut, START, 0)
    await Timer(400, unit="ns")

    frames = await cap.wait_for_frames(NUM_FRAMES)
    cap.stop()

    cap.check_timing(require_frames=NUM_FRAMES)
    cap.save_gif()
