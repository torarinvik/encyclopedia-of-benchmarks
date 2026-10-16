module bit_array_count_zero_bits;

fn long bit_array_count_zero_bits(long* values, usz length) @export("bit_array_count_zero_bits") {
    if (length > 4096 || (length != 0 && values == null)) return -1;
    long zero_count = 0;
    for (usz index = 0; index < length; index++) {
        if (values[index] != 0 && values[index] != 1) return -1;
        if (values[index] == 0) zero_count++;
    }
    return zero_count;
}
