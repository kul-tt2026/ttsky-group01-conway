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
import os
from cocotb.clock import Clock
from cocotb.triggers import Timer
from cocotb_vga import VGACapture, TinyVGA, VGA_640x480_60
from verify_PNGs import verify_PNGs

# zodat de gate-level simulatie werkt
GL = os.environ.get("GATES") == "yes"

# Bit positions for readability
UP, DOWN, LEFT, RIGHT, SET, START = 0, 1, 2, 3, 4, 5

# Number of frames to simulate
NUM_FRAMES = 12 * 4

FRAME = 39.722 * 420000  # ns, one full frame


async def reset(dut):
    dut.ui_in.value = 0
    dut.reset_n.value = 0
    dut.ena.value = 1
    await Timer(100, unit="ns")
    dut.reset_n.value = 1
    await Timer(100, unit="ns")


async def move_and_settle(dut, clear_bits, set_bits, hold_ns=10000, settle_ns=10000):
    """Clear old button bits, wait one settle period, then set new bits,
    then hold for the full press duration. Guarantees no same-timestamp
    overlap between releasing and pressing buttons."""
    cur = int(dut.ui_in.value)
    for bit in clear_bits:
        cur &= ~(1 << bit)
    dut.ui_in.value = cur
    await Timer(settle_ns, unit="ns")

    cur = int(dut.ui_in.value)
    for bit in set_bits:
        cur |= 1 << bit
    dut.ui_in.value = cur
    await Timer(hold_ns, unit="ns")


async def print_board(dut):
    if GL: return # volgens Claude gaat dit niet werken in de gate level simulatie
    board = dut.user_project.u_project_datapath.u_register_board.board0
    print("\n============ BOARD ============")
    for row in range(12):
        for i in range(16):
            index = row * 16 + i
            print(str(board[index].value), end=" ")
        print()
    print("===============================\n")


@cocotb.test()
async def test_project(dut):
    # Clock that matches VGA
    clock = Clock(dut.clk, 39.722, unit="ns")
    cocotb.start_soon(clock.start())

    await reset(dut)

    cap = VGACapture(
        dut.clk,
        TinyVGA(dut.uo_out),
        VGA_640x480_60,
        out_dir="output",
        name="vga_screen_capture",
    ).start()

    await Timer(FRAME, unit="ns")  # Wait one frame

    # Conway's Game of Life glider pattern:
    #   . X .
    #   . . X
    #   X X X
    # Cells (col, row) relative to anchor (1,1): (2,1), (3,2), (1,3), (2,3), (3,3)

    # Move to (1, 1)
    await move_and_settle(dut, clear_bits=[], set_bits=[RIGHT, DOWN])

    # Move to (2, 1) and set
    await move_and_settle(dut, clear_bits=[RIGHT, DOWN], set_bits=[RIGHT])
    await move_and_settle(dut, clear_bits=[RIGHT], set_bits=[SET])
    await print_board(dut)

    await Timer(FRAME, unit="ns")  # Wait one frame

    # Move to (3, 2) and set
    await move_and_settle(dut, clear_bits=[SET], set_bits=[RIGHT])
    await move_and_settle(dut, clear_bits=[RIGHT], set_bits=[DOWN])
    await move_and_settle(dut, clear_bits=[DOWN], set_bits=[SET])

    await print_board(dut)
    await Timer(FRAME, unit="ns")  # Wait one frame

    # Move to (3, 3) and set
    await move_and_settle(dut, clear_bits=[SET], set_bits=[DOWN])
    await move_and_settle(dut, clear_bits=[DOWN], set_bits=[SET])

    await print_board(dut)
    await Timer(FRAME, unit="ns")  # Wait one frame

    # Move to (2, 3) and set
    await move_and_settle(dut, clear_bits=[SET], set_bits=[LEFT])
    await move_and_settle(dut, clear_bits=[LEFT], set_bits=[SET])

    await print_board(dut)
    await Timer(FRAME, unit="ns")  # Wait one frame

    # Move to (1, 3) and set
    await move_and_settle(dut, clear_bits=[SET], set_bits=[LEFT])
    await move_and_settle(dut, clear_bits=[LEFT], set_bits=[SET])

    await print_board(dut)
    await Timer(FRAME, unit="ns")  # Wait one frame

    # Move to (3,1)
    await move_and_settle(dut, clear_bits=[SET], set_bits=[UP, RIGHT])
    await move_and_settle(dut, clear_bits=[UP, RIGHT], set_bits=[SET])
    await print_board(dut)

    await Timer(39.722 * 420000, unit="ns")  # Wait one frame

    # START
    await move_and_settle(dut, clear_bits=[SET], set_bits=[START])
    await move_and_settle(dut, clear_bits=[START], set_bits=[])
    await print_board(dut)

    frames = await cap.wait_for_frames(NUM_FRAMES)
    cap.stop()

    cap.check_timing(require_frames=NUM_FRAMES)
    cap.save_gif()

    # Algoritmische verificatie: zie andere file
    # gooit zelf errors indien nodig
    verify_PNGs("output")
