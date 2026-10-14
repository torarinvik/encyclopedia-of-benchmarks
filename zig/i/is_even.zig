/// Return 1 for an even signed 64-bit integer and 0 for an odd one.
export fn is_even(value: i64) i64 {
    return if (@rem(value, 2) == 0) 1 else 0;
}
