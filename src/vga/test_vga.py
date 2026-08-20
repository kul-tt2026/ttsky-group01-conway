import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def reset_dut(dut, cycles=5):
    dut.reset_n.value = 0
    dut.cursor_on.value = 0
    dut.cell_memory.value = 0
    dut.cursorpos.value = 0
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.reset_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def uo_out_bit_packing(dut):
    """Verify that uo_out is correctly packed from hsync, vsync, R, G, B
    on every clock cycle, regardless of internal pixel-pipeline state."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    for _ in range(200):
        dut.cursorpos.value = 0
        dut.cell_memory.value = 1
        dut.cursor_on.value = 0

        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")  # allow combinational settle

        hsync = int(dut.hsync.value)
        vsync = int(dut.vsync.value)
        r = int(dut.R.value)
        g = int(dut.G.value)
        b = int(dut.B.value)

        expected_uo_out = (
            (hsync << 7)
            | ((b & 0b01) << 6)
            | ((g & 0b01) << 5)
            | ((r & 0b01) << 4)
            | (vsync << 3)
            | (((b >> 1) & 0b01) << 2)
            | (((g >> 1) & 0b01) << 1)
            | ((r >> 1) & 0b01)
        )

        actual_uo_out = int(dut.uo_out.value)
        assert actual_uo_out == expected_uo_out, (
            f"uo_out mismatch: hsync={hsync}, vsync={vsync}, "
            f"R={r:#04b}, G={g:#04b}, B={b:#04b} -> "
            f"got {actual_uo_out:#010b}, expected {expected_uo_out:#010b}"
        )


@cocotb.test()
async def reset_drives_known_state(dut):
    """Check that after reset, the design comes up without X/undefined
    values propagating to uo_out."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    for _ in range(10):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")
        val = dut.uo_out.value
        assert (
            "x" not in str(val).lower() and "z" not in str(val).lower()
        ), f"uo_out contains undefined bits after reset: {val}"


@cocotb.test()
async def cell_type_pipeline_consistency(dut):
    """Cross-check that col_idx/row_idx computed by vga_get_cell_idx are
    correctly forwarded into vga_get_cell_type, verifying the internal
    wiring between submodules."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    for _ in range(50):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")

        col_idx_top = int(dut.col_idx.value)
        row_idx_top = int(dut.row_idx.value)
        col_idx_sub = int(dut.um_vga_get_cell_type.col_idx.value)
        row_idx_sub = int(dut.um_vga_get_cell_type.row_idx.value)

        assert (
            col_idx_top == col_idx_sub
        ), f"col_idx wiring mismatch: top={col_idx_top}, submodule={col_idx_sub}"
        assert (
            row_idx_top == row_idx_sub
        ), f"row_idx wiring mismatch: top={row_idx_top}, submodule={row_idx_sub}"


@cocotb.test()
async def pixel_offset_pipeline_consistency(dut):
    """Cross-check that pixel_col_offset/pixel_row_offset computed by
    vga_get_cell_idx are correctly forwarded into vga_get_pixel_color."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    for _ in range(50):
        await RisingEdge(dut.clk)
        await Timer(1, unit="ns")

        col_off_sub_idx = int(dut.um_vga_get_cell_idx.pixel_col_offset.value)
        row_off_sub_idx = int(dut.um_vga_get_cell_idx.pixel_row_offset.value)
        col_off_sub_color = int(dut.um_vga_get_pixel_color.pixel_col_offset.value)
        row_off_sub_color = int(dut.um_vga_get_pixel_color.pixel_row_offset.value)

        assert col_off_sub_idx == col_off_sub_color, (
            f"pixel_col_offset wiring mismatch: "
            f"cell_idx={col_off_sub_idx}, pixel_color={col_off_sub_color}"
        )
        assert row_off_sub_idx == row_off_sub_color, (
            f"pixel_row_offset wiring mismatch: "
            f"cell_idx={row_off_sub_idx}, pixel_color={row_off_sub_color}"
        )
