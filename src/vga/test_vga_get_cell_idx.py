import cocotb
from cocotb.triggers import Timer

H_DISPLAY = 640
V_DISPLAY = 480


@cocotb.test()
async def basic_cells(dut):
    """Basic checks for vga_get_cell_idx at a few positions."""

    # Parameters uit DUT of default
    num_cols = getattr(dut, "NUM_COLS", None)
    num_rows = getattr(dut, "NUM_ROWS", None)

    num_cols = num_cols.value.to_unsigned() if num_cols is not None else 16
    num_rows = num_rows.value.to_unsigned() if num_rows is not None else 12

    cell_width  = H_DISPLAY // num_cols
    cell_height = V_DISPLAY // num_rows

    async def check(h, v, name):
        dut.hpos.value = h
        dut.vpos.value = v
        await Timer(1, unit="ns")

        col = dut.col_idx.value.to_unsigned()
        row = dut.row_idx.value.to_unsigned()

        exp_col = h // cell_width
        exp_row = v // cell_height

        assert col == exp_col, f"{name}: col_idx={col}, expected {exp_col}"
        assert row == exp_row, f"{name}: row_idx={row}, expected {exp_row}"

    cocotb.log.info("top-left")
    await check(0, 0, "top-left")
    cocotb.log.info("edge col0")
    await check(cell_width - 1, 0, "edge col0")
    cocotb.log.info("start col1")
    await check(cell_width, 0, "start col1")
    cocotb.log.info("edge row0")
    await check(0, cell_height - 1, "edge row0")
    cocotb.log.info("start row1")
    await check(0, cell_height, "start row1")
    cocotb.log.info("middle (3, 2)")
    await check(3 * cell_width, 2 * cell_height, "middle (3,2)")
    cocotb.log.info("bottom-right")
    await check(H_DISPLAY - 1, V_DISPLAY - 1, "bottom-right")