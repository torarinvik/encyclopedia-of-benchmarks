/// XOR reduction for the signed 32-bit single-number contract.
export fn single_number(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 257) return -2_147_483_649;
    var bits: i64 = 0;
    for (values[0..length]) |value| {
        if (value < -2_147_483_648 or value > 2_147_483_647) return -2_147_483_649;
        const word = if (value < 0) value + 4_294_967_296 else value;
        bits ^= word;
    }
    return if (bits > 2_147_483_647) bits - 4_294_967_296 else bits;
}
