import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

# Expected color mapping when display_on = 1 and pause = 0, derived from the module's spec
EXPECTED_COLORS = {
    0b00: (0b00, 0b00, 0b00),  # dead -> black
    0b01: (0b11, 0b11, 0b11),  # alive -> white
    0b10: (0b00, 0b00, 0b11),  # cursor -> blue
    0b11: (0b11, 0b00, 0b00),  # default/invalid -> red
}

# Dead cell color depends on pause: black when not paused, grey when paused.
# All other cell types are unaffected by pause.
DEAD_COLOR_BY_PAUSE = {
    0: (0b00, 0b00, 0b00),  # not paused -> black
    1: (0b10, 0b10, 0b10),  # paused -> grey
}


def expected_color(display_on, cell_type, pause):
    if not display_on:
        return (0, 0, 0)
    if cell_type == 0b00:
        return DEAD_COLOR_BY_PAUSE[pause]
    return EXPECTED_COLORS[cell_type]


@cocotb.test()
async def exhaustive_pixel_color(dut):
    """Exhaustively check vga_get_pixel_color for every legal
    (display_on, cell_type, pause) combination. R/G/B are registered, so the
    color shows up one clock edge after the inputs are applied."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.reset_n.value = 0
    dut.display_on.value = 0
    dut.cell_type.value = 0
    dut.pause.value = 0
    await RisingEdge(dut.clk)
    dut.reset_n.value = 1

    checked = 0

    for display_on in (0, 1):
        for cell_type in range(4):  # cell_type is 2 bits wide -> 0..3
            for pause in (0, 1):

                dut.display_on.value = display_on
                dut.cell_type.value = cell_type
                dut.pause.value = pause

                await RisingEdge(dut.clk)  # inputs worden ingeklokt
                await Timer(1, unit="ns")  # laat de outputs settelen

                expected_r, expected_g, expected_b = expected_color(
                    display_on, cell_type, pause
                )

                actual_r = int(dut.R.value)
                actual_g = int(dut.G.value)
                actual_b = int(dut.B.value)

                assert (actual_r, actual_g, actual_b) == (
                    expected_r,
                    expected_g,
                    expected_b,
                ), (
                    f"Mismatch: display_on={display_on}, cell_type={cell_type:#04b}, "
                    f"pause={pause} -> got R={actual_r:#04b} G={actual_g:#04b} B={actual_b:#04b}, "
                    f"expected R={expected_r:#04b} G={expected_g:#04b} B={expected_b:#04b}"
                )
                checked += 1

    dut._log.info(f"Exhaustively checked {checked} combinations")


@cocotb.test()
async def pause_only_affects_dead_cells(dut):
    """Pause mag alleen de kleur van dode cellen veranderen (zwart -> grijs).
    Levende cellen, cursor en invalid moeten ongewijzigd blijven, ongeacht pause."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.reset_n.value = 0
    dut.display_on.value = 1
    dut.cell_type.value = 0
    dut.pause.value = 0
    await RisingEdge(dut.clk)
    dut.reset_n.value = 1

    for cell_type in (0b01, 0b10, 0b11):  # alive, cursor, invalid
        dut.cell_type.value = cell_type

        dut.pause.value = 0
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")
        color_unpaused = (int(dut.R.value), int(dut.G.value), int(dut.B.value))

        dut.pause.value = 1
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")
        color_paused = (int(dut.R.value), int(dut.G.value), int(dut.B.value))

        assert color_unpaused == color_paused == EXPECTED_COLORS[cell_type], (
            f"cell_type={cell_type:#04b}: pause changed the color unexpectedly "
            f"(unpaused={color_unpaused}, paused={color_paused}, "
            f"expected={EXPECTED_COLORS[cell_type]})"
        )


@cocotb.test()
async def dead_cell_pause_toggle(dut):
    """Dode cel moet omschakelen tussen zwart (pause=0) en grijs (pause=1)."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.reset_n.value = 0
    dut.display_on.value = 1
    dut.cell_type.value = 0b00
    dut.pause.value = 0
    await RisingEdge(dut.clk)
    dut.reset_n.value = 1

    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert (int(dut.R.value), int(dut.G.value), int(dut.B.value)) == (
        0b00,
        0b00,
        0b00,
    ), "Dead cell should be black when pause=0"

    dut.pause.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert (int(dut.R.value), int(dut.G.value), int(dut.B.value)) == (
        0b10,
        0b10,
        0b10,
    ), "Dead cell should be grey when pause=1"

    dut.pause.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert (int(dut.R.value), int(dut.G.value), int(dut.B.value)) == (
        0b00,
        0b00,
        0b00,
    ), "Dead cell should go back to black when pause=0 again"


@cocotb.test()
async def reset_clears_color(dut):
    """Reset moet de kleur op zwart zetten."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.reset_n.value = 1
    dut.display_on.value = 1
    dut.cell_type.value = 0b01  # wit
    dut.pause.value = 0
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
    ), "R/G/B zijn niet zwart na reset"
