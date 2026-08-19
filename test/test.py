"""
Button bit mapping in ui_in:
  ui_in[0] = up
  ui_in[1] = down
  ui_in[2] = left
  ui_in[3] = right
  ui_in[4] = set
  ui_in[5] = start/stop
  ui_in[6] = cursor on/off
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
# ui_in
UP, DOWN, LEFT, RIGHT, SET, START_STOP, CURSOR, BOUNDED = 0, 1, 2, 3, 4, 5, 6, 7
# uio_in
SPEED_UP, SPEED_DOWN, RESET, TESTING = 0, 1, 2, 7

# Number of frames to capture and verify. The capture now only starts once the
# simulation is running, so all of these are simulation frames (the earlier
# version captured 12 frames of which 6 still showed the cursor and were
# skipped by verify_PNGs, so this checks the same 5 Conway generations).
NUM_FRAMES = 6

# Voor de waveform moet je "make WAVES=yes" runnen in test/


async def reset(dut):
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.reset_n.value = 0
    dut.ena.value = 1
    await Timer(100, unit="ns")
    dut.reset_n.value = 1
    await Timer(100, unit="ns")


async def move_and_settle_ui_in(dut, clear_bits, set_bits, hold_ns=10000, settle_ns=10000):
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

async def move_and_settle_uio_in(dut, clear_bits, set_bits, hold_ns=10000, settle_ns=10000):
    """Clear old button bits, wait one settle period, then set new bits,
    then hold for the full press duration. Guarantees no same-timestamp
    overlap between releasing and pressing buttons."""
    cur = int(dut.uio_in.value)
    for bit in clear_bits:
        cur &= ~(1 << bit)
    dut.uio_in.value = cur
    await Timer(settle_ns, unit="ns")

    cur = int(dut.uio_in.value)
    for bit in set_bits:
        cur |= 1 << bit
    cur |= (
        1 << TESTING
    )  # zodat logica elke frame update, zowel in gewone als gate level tests
    dut.uio_in.value = cur
    await Timer(hold_ns, unit="ns")


async def print_board(dut):
    if GL:
        return  # volgens Claude gaat dit niet werken in de gate level simulatie
    board = dut.user_project.u_project_datapath.u_register_board.board0
    print("\n============ BOARD ============")
    for row in range(int(dut.user_project.ROWS.value)):
        for i in range(int(dut.user_project.COLS.value)):
            index = row * int(dut.user_project.COLS.value) + i
            print(str(board[index].value), end=" ")
        print()
    print("===============================\n")


@cocotb.test()
async def test_project(dut):
    # Clock that matches VGA
    clock = Clock(dut.clk, 39.722, unit="ns")
    cocotb.start_soon(clock.start())

    # aanpassen in project.sv
    if not GL:
        ROWS = int(dut.user_project.ROWS.value)
        COLS = int(dut.user_project.COLS.value)

    # Bounded mode wordt hier (nog) niet getest, maar heeft wel al eens succesvol getest op Sieben's computer

    await reset(dut)

    # Testing aanzetten
    await move_and_settle_uio_in(dut, clear_bits=[], set_bits=[TESTING])

    # Conway's Game of Life glider pattern:
    #   . X .
    #   . . X
    #   X X X
    # Cells (col, row) relative to anchor (1,1): (2,1), (3,2), (1,3), (2,3), (3,3)

    # # Move to (1, 1)
    # await move_and_settle(dut, clear_bits=[CURSOR], set_bits=[RIGHT, DOWN])

    # Move to (2, 1) and set
    await move_and_settle_ui_in(dut, clear_bits=[CURSOR], set_bits=[RIGHT])
    await move_and_settle_ui_in(dut, clear_bits=[RIGHT], set_bits=[SET])
    await print_board(dut)

    # Move to (3, 2) and set
    await move_and_settle_ui_in(dut, clear_bits=[SET], set_bits=[RIGHT])
    await move_and_settle_ui_in(dut, clear_bits=[RIGHT], set_bits=[DOWN])
    await move_and_settle_ui_in(dut, clear_bits=[DOWN], set_bits=[SET])

    await print_board(dut)

    # Move to (3, 3) and set
    await move_and_settle_ui_in(dut, clear_bits=[SET], set_bits=[DOWN])
    await move_and_settle_ui_in(dut, clear_bits=[DOWN], set_bits=[SET])

    await print_board(dut)

    # Move to (2, 3) and set
    await move_and_settle_ui_in(dut, clear_bits=[SET], set_bits=[LEFT])
    await move_and_settle_ui_in(dut, clear_bits=[LEFT], set_bits=[SET])

    await print_board(dut)

    # Move to (1, 3) and set
    await move_and_settle_ui_in(dut, clear_bits=[SET], set_bits=[LEFT])
    await move_and_settle_ui_in(dut, clear_bits=[LEFT], set_bits=[SET])

    await print_board(dut)

    # Start the frame capture only now: verify_PNGs skips the editing frames
    # (the ones with a blue cursor) anyway, and sampling the VGA bus every
    # clock cycle in Python is by far the slowest part of this test.
    cap = VGACapture(
        dut.clk,
        TinyVGA(dut.uo_out),
        VGA_640x480_60,
        out_dir="output",
        name="vga_screen_capture",
    ).start()

    # START
    await move_and_settle_ui_in(dut, clear_bits=[SET], set_bits=[START_STOP])
    await move_and_settle_ui_in(dut, clear_bits=[START_STOP], set_bits=[])
    await print_board(dut)

    frames = await cap.wait_for_frames(NUM_FRAMES)
    cap.stop()

    cap.check_timing(require_frames=NUM_FRAMES)
    cap.save_gif()

    # Algoritmische verificatie: zie andere file
    # gooit zelf errors indien nodig
    # De parameters voor ROWS en COLS werken niet in de GL simulatie
    if not GL:  verify_PNGs("output",mode=1,ROWS=ROWS,COLS=COLS)
    else:       verify_PNGs("output",mode=1,ROWS=12,COLS=16)
