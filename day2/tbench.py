import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

CLK_PERIOD = 10

@cocotb.test()
async def test_basic_packet(dut):
    f = open('input.txt')
    inputs = f.readline().split(',')
    f.close()

    ranges = []
    # Split string range ('n1-n2') to ['n1', 'n2']
    for s in inputs:
        ranges.append(s.split('-'))

    res = 0
    cocotb.start_soon(Clock(dut.i_clk, CLK_PERIOD, units="ns").start())
    dut.i_valid.value = 0
    dut.i_upper_bin.value = 0
    dut.i_lower_bin.value = 0
    dut.i_reset.value = 0
    await RisingEdge(dut.i_clk)
    dut.i_reset.value = 0
    await RisingEdge(dut.i_clk)
    dut.i_valid.value = 1
    for range in ranges:
        dut.i_upper_bin.value = int(range[1])
        dut.i_lower_bin.value = int(range[0])
        await RisingEdge(dut.i_clk)
    dut.i_valid.value = 0
    dut.i_upper_bin.value = 0
    dut.i_lower_bin.value = 0
    while dut.o_valid != 1:
        await RisingEdge(dut.i_clk)
#    while dut.o_valid == 1:
#        res += int(dut.o_res_bin.value)
#        await RisingEdge(dut.i_clk)

    print("RESULT: " + str(int(dut.o_duplicate_sum_bin.value)))