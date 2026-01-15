def get_digit_range(min_bound, max_bound, digit):
    if len(min_bound) > digit:
        return '', ''
    if len(max_bound) < digit:
        return '', ''
    if len(min_bound) < digit:
        min_bound = '1' + '0'*(digit-1)
    if len(max_bound) > digit:
        max_bound = '9' * digit
    return min_bound, max_bound

def get_sequence_range(min_bound, max_bound, digit, factor):
    if not min_bound or not max_bound:
        return (0, 0, 0)
    # Find the closest upper duplicate number when min_bond is
    # split into *factor* numbers. 
    # For example, 6 digit number with factor 3 is divided into
    # 3 numbers of len 2: 121213 is divided into - 12 12 13.
    # The closest upper duplicate is 13 13 13.
    base_len = digit // factor
    low_limit = int(min_bound[:base_len])
    for i in range(1,factor):
        if min_bound[:base_len] > min_bound[i*base_len:(i+1)*base_len]:
            break
        if min_bound[:base_len] < min_bound[i*base_len:(i+1)*base_len]:
            low_limit += 1
            break
    up_limit = int(max_bound[:base_len])
    for i in range(1,factor):
        if max_bound[:base_len] < max_bound[i*base_len:(i+1)*base_len]:
            break
        if max_bound[:base_len] > max_bound[i*base_len:(i+1)*base_len]:
            up_limit -= 1
            break
    if low_limit > up_limit:
        low_limit = up_limit = 0
    # first sequence element, second seq element, number of elements
    return (int(str(low_limit)*factor), int(str(up_limit)*factor), \
            up_limit-low_limit+1)
    
def get_duplicate_sum(init, last, n_elem):
    # the sequence of 11, 22, 33, 44 is an arithmetic progression
    # so it can be calculated using (a+a_n)*n/2 formula
    return ((last+init)*n_elem)//2

f = open('input.txt')
inputs = f.readline().split(',')
f.close()
#inputs = '11-22'
#inputs = inputs.split(',')

ranges = []
# Split string range ('n1-n2') to ['n1', 'n2']
for s in inputs:
    ranges.append(s.split('-'))

# Only consider 64 bit number ranges, hence:
# 2**64 - 1 is the max value, which has 20 digits.
# The minimum for duplication is 2 digits
min_digits = 2
max_digits = 20
# List of prime factors that are in range [2, 20].
prim_factors = [2, 3, 5, 7, 11, 13, 17, 19]
total = 0
for r in ranges:
    # Find sum of invalid numbers for each digit range separately.
    # For example, if the total range is 10-9999,
    # find sums at ranges 10 - 99, 100-999, and 1000-9999.
    for digit in range(min_digits, max_digits+1):
        n_div_prim = 0
        # fetch the numbers in range "r" that belong to current digit range
        min_bound, max_bound = get_digit_range(r[0], r[1], digit)
        for prim in prim_factors:
            if digit % prim:
                continue # skip if not a prime factor of this digit range
            n_div_prim += 1
            first, last, n_elem = get_sequence_range(min_bound, max_bound, digit, prim)
            total += get_duplicate_sum(first, last, n_elem)
        # Numbers in which all digits are the same, like 1111, 2222, 3333
        # are calculated in each range, meaning that the total sum has
        # duplicates. The following removes the duplicates
        
        if n_div_prim > 1:
            first, last, n_elem = get_sequence_range(min_bound, max_bound, digit, digit)
            total -= get_duplicate_sum(first, last, n_elem)*(n_div_prim-1)
print("The sum of invalid numbers is " + str(total))