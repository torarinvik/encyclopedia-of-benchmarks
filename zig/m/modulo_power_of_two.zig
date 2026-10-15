/// Java-compatible low-bit mask for a signed 32-bit input and exponent 1..31.
export fn modulo_power_of_two(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const x = values[0];
    const exponent = values[1];
    if (x < -2_147_483_648 or x > 2_147_483_647 or exponent < 1 or exponent > 31) return -1;
    const mask: i64 = (@as(i64, 1) << @intCast(exponent)) - 1;
    return x & mask;
}
