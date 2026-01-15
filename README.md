# Submission to Advent of FPGA Contest

**As the contest requires inventive&creative approach, I decided to focus on only one particular puzzle.** 

## Day 2 Puzzle
The main purpose of this puzzle is, given a certain range of numbers N1 to N2, **find the sum of all invalid numbers**.

The number is considered invalid, if, when it is divided into equal-length subnumbers, **all subnumbers' values are equal to each other**.

For example, given range **10-22**, a number **10** can be divided into **1 - 0**, a number **11** can be divided into **1 - 1**, and so on.

Here, the number **11** is considered as **invalid**, since **1 = 1**.

So, overall, in range **10-22**, there are 2 invalid numbers: **11 and 22**. The sum of 2 (and **the answer**) is **33**.
### Day 2a
    For this puzzle, a given number had to be divided only on 2 subnumbers.
    For example, 100001 -> 100-001.
### Day 2b
    For this puzzle, a given number had to be divided on any possible subnumbers. 

For example, **100001** -> into 6 subnumbers **1-0-0-0-0-1**, into 3 subnumbers **10-00-01**, and into 2 subnumbers **100-001**.

## Brute Force Solution (not implemented)
Go through each number in the range, and check if it is an invalid number. It can be implemented using pipelines or FSM.

1. A pipelined design would check each number in the range one-by-one.

   **Pros:** constant throughput of one range per cycle (or more)

   **Cons:** if the possible range is too big (say [10, 1000000000]), it would not fit in any of the available FPGAs!

2. An FSM design would focus only on one range, not accepting any other input while processing the current input.

   **Pros:** minimal resource consumption.

   **Cons:** poor throughput, undeterministic latency (the latency would depend on the size of the input range).
<!-- -->

    As a contrast, the implemented solution has moderate resource consumption, constant throughput, 
    and deterministic latency.

## Implemented Solution
**Day 2b is basically a superset of Day 2a. Therefore, only the solution for Day 2b is shown in this submission.**

#### <ins> Main idea is to find the sum of all invalid numbers in a given range using the sum of arithmetic sequences. </ins>


Let's consider a range of numbers, in which a **start** and an **end** have the same **number of digits**. For example, **10-99**.

The **number of digits** in all numbers in the range is **2**. The number 2 has only one factor: 2.

It means we can **split every number** into **2 subnumbers** and find an *invalid number* we are searching: **10 -> 1-0, 11 -> 1-1**, etc.

After a careful observation, <ins>**all invalid numbers belonging to this subnumber factor, form an arithmetic sequence**</ins>: **1-1, 2-2, 3-3, 4-4, ...**

Hence, the sum of invalid numbers for subnumber factor 2 is a sum of arithmetic sequence in range **[11, 99]**.

The sequence can be defined as **a_start = 11, a_end = 99, n_elems = (9-1)+1 = 9**.

The total sum of arithmetic sequence is **(a_start + a_end) * n_elems / 2** = **495**.

### Nuances
**Nuance #1.** Given a number with N number of digits, the number should only be split into the prime factors of N.

    Let's consider 8-digit numbers. The split factors for 8-digit numbers are 2, 4, and 8.

    Number 44444444 can be split into: factor 8 -> 4-4-4-4-4-4-4-4, factor 4 -> 44-44-44-44, and factor 2 -> 4444-4444.
    Number 42424242 can be split into: factor 8 -> 4-2-4-2-4-2-4-2, factor 4 -> 42-42-42-42, and factor 2 -> 4242-4242.
    Number 42224222 can be split into: factor 8 -> 4-2-2-2-4-2-2-2, factor 4 -> 42-22-42-22, and factor 2 -> 4222-4444.
   
    Observation: invalid numbers with split factor 2 are superset of the invalid numbers 
                 with split factors 4 and 8. 

**Nuance #2.** In case there are several prime factors, there are overlapping numbers that have to be removed from the final sum.

    Now, let's consider 6-digit numbers. The split factors of 6-digit numbers are 2, 3 and 6.
    
    Number 225225 can be split into: factor 6 -> 2-2-5-2-2-5, factor 3 -> 22-52-25, factor 2 -> 225-225.
    Number 232323 can be split into: factor 6 -> 2-3-2-3-2-3, factor 3 -> 23-23-23, factor 2 -> 232-323.
    Number 222222 can be split into: factor 6 -> 2-2-2-2-2-2, factor 3 -> 22-22-22, factor 2 -> 222-222.

    Observation: Both, set of split factor 2 overlap and set of split factor 3, 
                 contains set of split factor 6.
                     
**Nuance #3.** When numbers in the input range have different number of digits, the sequence sum has to be calculated separately for each number of digits.

    Let's consider range [88-444]. The list of all invalid numbers is [88, 99, 111, 222, 333, 444].

    By the definition of arithmetic sequence, the next number in the sequence after [88, 99] 
                                              should be 110 (99+11), which is not true.

    Hence, we have to calculate two sequence sums: for 2-digit numbers, and for 3-digit numbers.

## Implementation

**1. Given a stream of valid input ranges (1 per cycle), the module finds a sum of invalid numbers in each range, and accumulates it in an output register.
The output register is reset, when a stream pauses even for 1 cycle.**

**2. The implementation supports up to 20-digit ranges (can be parameterized for even more).**

**3. That being said, the sum might overflow in case the list of input ranges is too large.**

    Inputs: a 1-bit valid signal, and a 64-bit lower and an upper bound of the input range.
    Outputs: a 1-bit output valid signal, 
             an accumulated 128-bit sum of all input ranges in the ongoing of valid ranges stream.

### Input processing
1. Input is converted from binary to BCD.

2. BCD range is fed to 18 (from 2 to 20) sequence sum calculators to satisfy Nuance #3.

3. Inside the seq. sum calculators, the lower and upper bounds are clipped.

   For example, given the range 1-10000, 2-digit seq. sum calculator clips the range to 10-99.

   If the lower and boundaries are out of the range, the values are clipped to 0.

4. Clipped bounds are fed to sequence boundary finders, each seq. sum N has a base factor N and P primary factors (Nuance #1), depending on the N.

   For example, in 6-digit seq. sum has a base factor 6, and prime factors of 2 and 3.

5. Each sequence boundary finders outputs binary values of first_elem, last_elem, n_elems_lower, n_elems_upper, exclude_first, and exclude_last.

   **first_elem and last_elem** are first and last element of the sequence.

   The first and last elements are found by extrapolating the most significant subnumber.

   Let's consider, **lower_bound is 121314** and **prime factor of 3**. Subnumbers are **12-13-14**. 12 is **extrapolated**, so first_elem is **12-12-12**.

   We can do the same thing with last_elem.

   **Note:** in this case, **first_elem is out of range** (121212 is lower than lower bound 121314), hence, we set exclude first.

   **exclude_first**, and **exclude_last** are flags set when **extrapolated first/last_elem are out of range**.
   
   **n_elems_lower and n_elems_upper** are used to find **total number of elements** in the sequence **n_elem = n_elems_upper - n_elems_lower + 1**.

7. **first_elem, last_elem, and n_elems** are used to find the sequence sum. **first_elem and/or last_elem** are then **subtracted** from the sequence sum if **exclude_first or exclude_last are set**.
8. Once sequence sums are calculated for base factor and prime factors, the **base factor seq. sum** is **subtracted from all prime factors seq. sum** to exclude overlaps mentioned in **Nuance #2**. 
9. The resulting prime factor sequence sums and the base factor sequence sum are added using **adder tree**.
10. Cross-factor sequence sum from each digit N is then added through cross-digit adder tree.
11. The result of cross-digit adder tree is accumulated in the output register.
    
<img width="2242" height="1512" alt="image" src="https://github.com/user-attachments/assets/522c6032-c996-4f14-93cc-bdae1b43f363" />

## Simulation
The design was simulated using Cocotb & Verilator. The cocotb testbench is available in the repository.
## Synthesis
The module was synthesized on Vivado for Kintex-7 XC7K325T-FFG676-2. Timing constraints are met at 50 MHz. FPGA utilization is attached below.

<img width="485" height="148" alt="image" src="https://github.com/user-attachments/assets/4a415d3b-3e8e-4da8-a5f2-98e9774bbb04" />


    
