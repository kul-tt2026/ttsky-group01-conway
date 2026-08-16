import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


# Expected color mapping when display_on = 1, derived from the module's spec
EXPECTED_COLORS = {
    0b00: (0b00, 0b00, 0b00),  # dead -> black
    0b01: (0b11, 0b11, 0b11),  # alive -> white
    0b10: (0b00, 0b00, 0b11),  # cursor -> blue
    0b11: (0b11, 0b00, 0b00),  # default/invalid -> red
}


@cocotb.test()
async def exhaustive_pixel_color(dut):
    """Exhaustively check vga_get_pixel_color for every legal
    (display_on, cell_type) combination. R/G/B are registered, so the
    color shows up one clock edge after the inputs are applied."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.reset_n.value = 0
    dut.display_on.value = 0
    dut.cell_type.value = 0
    await RisingEdge(dut.clk)
    dut.reset_n.value = 1

    checked = 0

    for display_on in (0, 1):
        for cell_type in range(4):  # cell_type is 2 bits wide -> 0..3

            dut.display_on.value = display_on
            dut.cell_type.value = cell_type

            await RisingEdge(dut.clk)  # inputs worden ingeklokt
            await Timer(1, unit="ns")  # laat de outputs settelen

            if display_on:
                expected_r, expected_g, expected_b = EXPECTED_COLORS[cell_type]
            else:
                expected_r, expected_g, expected_b = 0, 0, 0

            actual_r = int(dut.R.value)
            actual_g = int(dut.G.value)
            actual_b = int(dut.B.value)

            assert (actual_r, actual_g, actual_b) == (expected_r, expected_g, expected_b), (
                f"Mismatch: display_on={display_on}, cell_type={cell_type:#04b} -> "
                f"got R={actual_r:#04b} G={actual_g:#04b} B={actual_b:#04b}, "
                f"expected R={expected_r:#04b} G={expected_g:#04b} B={expected_b:#04b}"
            )
            checked += 1

    dut._log.info(f"Exhaustively checked {checked} combinations")


@cocotb.test()
async def reset_clears_color(dut):
    """Reset moet de kleur op zwart zetten."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.reset_n.value = 1
    dut.display_on.value = 1
    dut.cell_type.value = 0b01  # wit
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert (int(dut.R.value), int(dut.G.value), int(dut.B.value)) == (0b11, 0b11, 0b11)

    dut.reset_n.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    assert (int(dut.R.value), int(dut.G.value), int(dut.B.value)) == (0, 0, 0), (
        "R/G/B zijn niet zwart na reset"
    )
