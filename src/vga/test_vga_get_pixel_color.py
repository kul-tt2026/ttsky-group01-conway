import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

CELL_SIZE = 40


def icon_bit(row, col):
    """Replicates the filled-diamond icon bitmap from the RTL."""
    center = (CELL_SIZE - 1) / 2
    half = CELL_SIZE / 2
    dx = abs(col - center)
    dy = abs(row - center)
    return 1 if dx + dy <= half else 0


def expected_color(display_on, cursor_on, cell_alive, running, row_off, col_off):
    if not display_on:
        return (0, 0, 0)

    if cursor_on and icon_bit(row_off, col_off):
        return (0b00, 0b00, 0b11)  # inside diamond -> blue, regardless of cell state

    if cell_alive:
        return (0b11, 0b11, 0b11)  # alive -> white

    # dead, no diamond pixel here
    return (0b00, 0b00, 0b00) if running else (0b10, 0b10, 0b10)


@cocotb.test()
async def pixel_color_grid_sample(dut):
    """Check color at representative pixel offsets (corners, center,
    diamond edge, outside diamond) for every (cursor_on, cell_alive,
    running, display_on) combination. Full 40x40 offset sweep would be
    6400 combinations per state; this samples key points instead."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.reset_n.value = 0
    dut.display_on.value = 0
    dut.cell_type.value = 0
    dut.running.value = 1
    dut.pixel_col_offset.value = 0
    dut.pixel_row_offset.value = 0
    await RisingEdge(dut.clk)
    dut.reset_n.value = 1

    sample_offsets = [
        (0, 0),  # corner, outside diamond
        (19, 19),  # near center, inside diamond
        (20, 20),  # near center, inside diamond
        (0, 19),  # top edge, inside diamond tip
        (19, 0),  # left edge, inside diamond tip
        (39, 39),  # opposite corner, outside diamond
        (5, 5),  # off-diamond region
    ]

    checked = 0
    for display_on in (0, 1):
        for cursor_on in (0, 1):
            for cell_alive in (0, 1):
                for running in (0, 1):
                    for row_off, col_off in sample_offsets:
                        cell_type = (cursor_on << 1) | cell_alive

                        dut.display_on.value = display_on
                        dut.cell_type.value = cell_type
                        dut.running.value = running
                        dut.pixel_row_offset.value = row_off
                        dut.pixel_col_offset.value = col_off

                        await RisingEdge(dut.clk)
                        await Timer(1, unit="ns")

                        exp_r, exp_g, exp_b = expected_color(
                            display_on, cursor_on, cell_alive, running, row_off, col_off
                        )
                        act_r = int(dut.R.value)
                        act_g = int(dut.G.value)
                        act_b = int(dut.B.value)

                        assert (act_r, act_g, act_b) == (exp_r, exp_g, exp_b), (
                            f"Mismatch: display_on={display_on}, cursor_on={cursor_on}, "
                            f"cell_alive={cell_alive}, running={running}, "
                            f"offset=(row={row_off},col={col_off}) -> "
                            f"got R={act_r:#04b} G={act_g:#04b} B={act_b:#04b}, "
                            f"expected R={exp_r:#04b} G={exp_g:#04b} B={exp_b:#04b}"
                        )
                        checked += 1

    dut._log.info(f"Checked {checked} combinations")


@cocotb.test()
async def diamond_shape_full_sweep(dut):
    """Full 40x40 pixel sweep with cursor_on=1, cell_alive=0, running=1,
    verifying the diamond boundary matches the RTL icon exactly."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.reset_n.value = 0
    dut.display_on.value = 1
    dut.cell_type.value = 0b10  # cursor on, dead cell
    dut.running.value = 1
    await RisingEdge(dut.clk)
    dut.reset_n.value = 1

    mismatches = 0
    for row_off in range(CELL_SIZE):
        for col_off in range(CELL_SIZE):
            dut.pixel_row_offset.value = row_off
            dut.pixel_col_offset.value = col_off
            await RisingEdge(dut.clk)
            await Timer(1, unit="ns")

            inside = icon_bit(row_off, col_off)
            expected = (0b00, 0b00, 0b11) if inside else (0b00, 0b00, 0b00)
            actual = (int(dut.R.value), int(dut.G.value), int(dut.B.value))
            if actual != expected:
                dut._log.error(
                    f"row={row_off}, col={col_off}: inside_diamond={inside}, "
                    f"got {actual}, expected {expected}"
                )
                mismatches += 1

    assert (
        mismatches == 0
    ), f"{mismatches} pixel(s) did not match expected diamond shape"


@cocotb.test()
async def reset_clears_color(dut):
    """Reset should make unselected pixels black."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.reset_n.value = 1
    dut.display_on.value = 1
    dut.cell_type.value = 0b01  # alive
    dut.running.value = 1
    dut.pixel_row_offset.value = 0
    dut.pixel_col_offset.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert (int(dut.R.value), int(dut.G.value), int(dut.B.value)) == (0b11, 0b11, 0b11)

    dut.reset_n.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert (int(dut.R.value), int(dut.G.value), int(dut.B.value)) == (
        0,
        0,
        0,
    ), "R/G/B are not black after reset"
