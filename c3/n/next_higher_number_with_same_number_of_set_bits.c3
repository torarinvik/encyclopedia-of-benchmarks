module next_higher_number_with_same_number_of_set_bits;

// Return the next larger positive integer with the same population count.
fn long next_higher_number_with_same_number_of_set_bits(long input)
    @export("next_higher_number_with_same_number_of_set_bits")
{
    if (input < 1 || input > 1073741823) return -1;
    long right_one = input & -input;
    long next_higher = input + right_one;
    long packed_ones = (input ^ next_higher) / right_one;
    packed_ones >>= 2;
    return next_higher | packed_ones;
}
