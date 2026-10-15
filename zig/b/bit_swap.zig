/// Swap two 0-based bits in a signed 32-bit value.
export fn bit_swap(values: [*]const i64, length: usize) i64 {
    if (length != 3) return -2_147_483_649;
    const data = values[0];
    const pos_a = values[1];
    const pos_b = values[2];
    if (data < -2_147_483_648 or data > 2_147_483_647 or pos_a < 0 or pos_a >= 32 or pos_b < 0 or pos_b >= 32) return -2_147_483_649;
    var bits: u32 = @bitCast(@as(i32, @intCast(data)));
    const shift_a: u5 = @intCast(pos_a);
    const shift_b: u5 = @intCast(pos_b);
    const mask_a = @as(u32, 1) << shift_a;
    const mask_b = @as(u32, 1) << shift_b;
    const bit_a = (bits >> shift_a) & 1;
    const bit_b = (bits >> shift_b) & 1;
    if (bit_a != bit_b) bits ^= mask_a ^ mask_b;
    return @as(i64, @as(i32, @bitCast(bits)));
}
