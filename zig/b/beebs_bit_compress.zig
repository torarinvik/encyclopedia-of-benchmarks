pub export fn beebs_bit_compress(values: ?[*]const i64, length: usize) i64 {
    const v = values orelse return -1;
    if (length != 2 or v[0] < 0 or v[0] > 4_294_967_295 or
        v[1] < 0 or v[1] > 4_294_967_295) return -1;
    var data: u32 = @intCast(v[0]);
    var mask: u32 = @intCast(v[1]);
    var packed: u32 = 0;
    var output_bit: u32 = 1;
    while (mask != 0) {
        if (mask & 1 != 0) {
            if (data & 1 != 0) packed |= output_bit;
            output_bit <<= 1;
        }
        data >>= 1;
        mask >>= 1;
    }
    return @intCast(packed);
}
