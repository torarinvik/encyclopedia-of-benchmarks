/// Interpret most-significant-first bits in radix -2 with checked i64 folding.
export fn negative_binary_base_to_int(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 63) return -1;
    var value: i64 = 0;
    for (0..length) |index| {
        const bit = input[index];
        if (bit != 0 and bit != 1) return -1;
        if (value > 4611686018427387904 or value < -4611686018427387903) return -1;
        value = value * -2 + bit;
    }
    return value;
}
