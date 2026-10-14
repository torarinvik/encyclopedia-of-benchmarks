module negative_binary_base_to_int;

// Interpret most-significant-first bits in radix -2 with checked i64 folding.
fn long negative_binary_base_to_int(long* input, usz length) @export("negative_binary_base_to_int") {
    if (length < 1 || length > 63) return -1;
    long value = 0;
    for (usz index = 0; index < length; index++) {
        long bit = input[index];
        if (bit != 0 && bit != 1) return -1;
        if (value > 4611686018427387904 || value < -4611686018427387903) return -1;
        value = value * -2 + bit;
    }
    return value;
}
