/// Reverse the eight bytes in a 64-bit bit pattern.
export fn byte_encoding_utils(value: i64) i64 {
    return @bitCast(@byteSwap(@as(u64, @bitCast(value))));
}
