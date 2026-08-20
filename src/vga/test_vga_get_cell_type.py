import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def exhaustive_cell_type(dut):
    """Exhaustively check vga_get_cell_type for every legal input
    combination. cell_type[1]=cursor_on, cell_type[0]=cell_memory,
    independent bits — cursor overlay no longer masks cell state."""

    num_cols = int(dut.NUM_COLS.value)
    num_rows = int(dut.NUM_ROWS.value)
    row_bits = int(dut.ROW_BITS.value)

    checked = 0

    for curs_on in (0, 1):
        for cell_mem in (0, 1):
            for col_idx in range(num_cols):
                for row_idx in range(num_rows):
                    for cursor_col in range(num_cols):
                        for cursor_row in range(num_rows):

                            dut.cursor_on.value = curs_on
                            dut.col_idx.value = col_idx
                            dut.row_idx.value = row_idx
                            dut.cell_memory.value = cell_mem
                            dut.cursorpos.value = (cursor_col << row_bits) | cursor_row

                            await Timer(1, unit="ns")

                            cursor_match = (cursor_col == col_idx) and (
                                cursor_row == row_idx
                            )
                            expect_cursor = curs_on and cursor_match

                            expected = (int(expect_cursor) << 1) | cell_mem

                            actual = int(dut.cell_type.value)
                            assert actual == expected, (
                                f"Mismatch: cursor_on={curs_on}, "
                                f"col_idx={col_idx}, row_idx={row_idx}, "
                                f"cursor=({cursor_col},{cursor_row}), "
                                f"cell_mem={cell_mem} -> got {actual:#04b}, "
                                f"expected {expected:#04b}"
                            )
                            checked += 1

    dut._log.info(
        f"Exhaustively checked {checked} combinations "
        f"for NUM_COLS={num_cols}, NUM_ROWS={num_rows}"
    )
