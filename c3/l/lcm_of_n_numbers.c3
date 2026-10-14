module lcm_of_n_numbers;

// Fold a list of nonnegative values with overflow-safe Euclidean LCM.
fn long lcm_of_n_numbers(long* values, usz length) @export("lcm_of_n_numbers")
{
    for (usz index = 0; index < length; index++) {
        if (values[index] == 0) return 0;
    }
    ulong accumulator = 1;
    ulong maximum = 9223372036854775807;
    for (usz index = 0; index < length; index++) {
        ulong left = accumulator;
        ulong value = (ulong)values[index];
        ulong right = value;
        while (right != 0) {
            ulong remainder = left % right;
            left = right;
            right = remainder;
        }
        ulong reduced = accumulator / left;
        if (reduced > maximum / value) return -1;
        accumulator = reduced * value;
    }
    return (long)accumulator;
}
