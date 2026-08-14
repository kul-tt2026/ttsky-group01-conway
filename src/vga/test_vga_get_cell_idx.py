import cocotb
from cocotb.triggers import Timer


H_DISPLAY = 640
V_DISPLAY = 480

# Typical full VGA frame extents (visible + blanking), used to test
# that out-of-display positions are safely clamped to (0, 0).
H_TOTAL = 800
V_TOTAL = 525


@cocotb.test()
async def basic_cells(dut):
    """Basic checks for vga_get_cell_idx at a few positions, including
    blanking-region positions that must be clamped to (0, 0)."""

    # Parameters uit DUT of default
    num_cols = getattr(dut, "NUM_COLS", None)
    num_rows = getattr(dut, "NUM_ROWS", None)

    num_cols = num_cols.value.to_unsigned() if num_cols is not None else 16
    num_rows = num_rows.value.to_unsigned() if num_rows is not None else 12

    cell_width  = H_DISPLAY // num_cols
    cell_height = V_DISPLAY // num_rows

    async def check(h, v, display_on, name):
        dut.hpos.value = h
        dut.vpos.value = v
        dut.display_on.value = display_on
        await Timer(1, unit="ns")

        col = dut.col_idx.value.to_unsigned()
        row = dut.row_idx.value.to_unsigned()

        if display_on and h < H_DISPLAY and v < V_DISPLAY:
            exp_col = h // cell_width
            exp_row = v // cell_height
        else:
            # Outside the visible display (or display_on low): must be
            # safely clamped to (0, 0), never wrap or go out of range.
            exp_col = 0
            exp_row = 0

        assert col == exp_col, f"{name}: col_idx={col}, expected {exp_col}"
        assert row == exp_row, f"{name}: row_idx={row}, expected {exp_row}"
        assert col < num_cols, f"{name}: col_idx={col} out of range (num_cols={num_cols})"
        assert row < num_rows, f"{name}: row_idx={row} out of range (num_rows={num_rows})"

    cocotb.log.info("top-left")
    await check(0, 0, 1, "top-left")
    cocotb.log.info("edge col0")
    await check(cell_width - 1, 0, 1, "edge col0")
    cocotb.log.info("start col1")
    await check(cell_width, 0, 1, "start col1")
    cocotb.log.info("edge row0")
    await check(0, cell_height - 1, 1, "edge row0")
    cocotb.log.info("start row1")
    await check(0, cell_height, 1, "start row1")
    cocotb.log.info("middle (3, 2)")
    await check(3 * cell_width, 2 * cell_height, 1, "middle (3,2)")
    cocotb.log.info("bottom-right")
    await check(H_DISPLAY - 1, V_DISPLAY - 1, 1, "bottom-right")

    # --- Blanking / out-of-display checks ---
    cocotb.log.info("horizontal blanking (display_on low, hpos in blanking)")
    await check(H_DISPLAY + 10, 0, 0, "h-blanking")
    cocotb.log.info("vertical blanking (display_on low, vpos in blanking)")
    await check(0, V_DISPLAY + 10, 0, "v-blanking")
    cocotb.log.info("full blanking corner (max hpos/vpos)")
    await check(H_TOTAL - 1, V_TOTAL - 1, 0, "full-blanking-corner")
    cocotb.log.info("display_on high but hpos out of visible range (edge case)")
    await check(H_DISPLAY + 5, 0, 1, "display_on-high-but-hpos-oob")
    cocotb.log.info("display_on high but vpos out of visible range (edge case)")
    await check(0, V_DISPLAY + 5, 1, "display_on-high-but-vpos-oob")
