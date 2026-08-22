import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge
from pyConway import Grid, PyConway

# Watchdog
@cocotb.test(timeout_time=1000, timeout_unit="ms")
async def test_project(dut):
    dut._log.info("Start")

    ROWS = 12
    COLS = 16

    # Python
    pyGrid = Grid(ROWS, COLS)

    
    # Reset
    dut._log.info("Reset")
    dut.L_reset.value = 0
    dut.L_next_iter.value = 0
    dut.reset_n.value = 0
    dut.L_mode.value = 0
    await ClockCycles(dut.clk, 10)
    dut.reset_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Inititiële situatie klaarzetten")
    dut.init.value = 1

    def set_value(row, col, value):
        pyGrid.set(row, col, value)
        dut.init_row.value = row
        dut.init_col.value = col
        dut.init_write_data.value = value

    # twee tetrisvormen
    #     X
    #   X X X  
    set_value(3,3,1)
    await ClockCycles(dut.clk, 1)
    set_value(3,4,1)
    await ClockCycles(dut.clk, 1)
    set_value(3,5,1)
    await ClockCycles(dut.clk, 1)
    set_value(2,4,1)
    await ClockCycles(dut.clk, 1)

    set_value(11,12,1)
    await ClockCycles(dut.clk, 1)
    set_value(11,13,1)
    await ClockCycles(dut.clk, 1)
    set_value(11,14,1)
    await ClockCycles(dut.clk, 1)
    set_value(10,13,1)
    await ClockCycles(dut.clk, 1)


    dut.init.value = 0
    dut._log.info("Simulatie laten runnen")
    pySim = PyConway(pyGrid, 0)

    def check_grids():
        for row in range(ROWS):
            for col in range(COLS):
                py = pySim.get_grid().get(row, col)
                sv = dut.u_register_board.board0.value[row*COLS + col]
                if py != int(sv): pySim.get_grid().print()
                assert py == int(sv), f"ERROR: iteratie {i}, rij {row}, kolom {col}, python had {py}, verilog {sv}"

    for i in range(20):
        dut.L_next_iter.value = 1
        await ClockCycles(dut.clk, 5)
        dut.L_next_iter.value = 0

        await dut.L_idle.rising_edge
        pySim.advance()

        check_grids()


    # TWEEDE TEST: BOUNDED

    pyGrid = Grid(ROWS, COLS)
    
    # Reset
    dut._log.info("Reset")
    dut.L_reset.value = 0
    dut.L_next_iter.value = 0
    dut.reset_n.value = 0
    dut.L_mode.value = 1
    await ClockCycles(dut.clk, 10)
    dut.reset_n.value = 1
    await ClockCycles(dut.clk, 5)

    dut._log.info("Tweede situatie klaarzetten")
    dut.init.value = 1

    def set_value(row, col, value):
        pyGrid.set(row, col, value)
        dut.init_row.value = row
        dut.init_col.value = col
        dut.init_write_data.value = value

    # Twee tetrisvormen
    #     X
    #   X X X
    set_value(3,3,1)
    await ClockCycles(dut.clk, 1)
    set_value(3,4,1)
    await ClockCycles(dut.clk, 1)
    set_value(3,5,1)
    await ClockCycles(dut.clk, 1)
    set_value(2,4,1)
    await ClockCycles(dut.clk, 1)

    set_value(11,12,1)
    await ClockCycles(dut.clk, 1)
    set_value(11,13,1)
    await ClockCycles(dut.clk, 1)
    set_value(11,14,1)
    await ClockCycles(dut.clk, 1)
    set_value(10,13,1)
    await ClockCycles(dut.clk, 1)


    dut.init.value = 0
    dut._log.info("Simulatie laten runnen")
    pySim = PyConway(pyGrid,mode=1)

    for i in range(20):
        dut.L_next_iter.value = 1
        await ClockCycles(dut.clk, 5)
        dut.L_next_iter.value = 0

        await dut.L_idle.rising_edge
        pySim.advance()
        
        check_grids()

