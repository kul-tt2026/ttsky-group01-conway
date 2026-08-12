import cocotb
from cocotb.triggers import Timer


# Expected color mapping when display_on = 1, derived from the module's spec
EXPECTED_COLORS = {
    0b00: (0b00, 0b00, 0b00),  # dead -> black
    0b01: (0b11, 0b11, 0b11),  # alive -> white
    0b10: (0b00, 0b00, 0b11),  # cursor -> blue
    0b11: (0b11, 0b00, 0b00),  # default/invalid -> red
}


@cocotb.test()
async def exhaustive_pixel_color(dut):
    """Exhaustively check vga_set_pixel_color for every legal
    (display_on, cell_type) combination."""

    checked = 0

    for display_on in (0, 1):
        for cell_type in range(4):  # cell_type is 2 bits wide -> 0..3

            dut.display_on.value = display_on
            dut.cell_type.value = cell_type

            await Timer(1, units="ns")

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