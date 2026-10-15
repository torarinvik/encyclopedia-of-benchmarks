/// Return the next larger positive integer with the same population count.
export fn next_higher_number_with_same_number_of_set_bits(input: i64) i64 {
    if (input < 1 or input > 1_073_741_823) return -1;
    const right_one = input & -input;
    const next_higher = input + right_one;
    const packed_ones = @divTrunc(input ^ next_higher, right_one);
    return next_higher | (packed_ones >> 2);
}
