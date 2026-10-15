/// Return 1 for an odd signed 64-bit integer and 0 for an even one.
export fn is_odd(value: i64) i64 {
    return if (@rem(value, 2) != 0) 1 else 0;
}
