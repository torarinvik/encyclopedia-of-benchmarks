/// Return the zero-based index of the most significant set bit.
export fn highest_set_bit(input: i64) i64 {
    if (input <= 0) return -1;
    var remaining: u64 = @intCast(input);
    var position: i64 = 0;
    while (remaining > 1) : (position += 1) {
        remaining >>= 1;
    }
    return position;
}
