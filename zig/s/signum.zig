/// Sign of a signed 64-bit integer.
export fn signum(value: i64) i64 {
    if (value > 0) return 1;
    if (value < 0) return -1;
    return 0;
}
