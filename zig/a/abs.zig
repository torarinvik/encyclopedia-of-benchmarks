/// Return the signed 64-bit magnitude, or -1 when it cannot be represented.
export fn abs_i64(input: i64) i64 {
    if (input == -9223372036854775807 - 1) return -1;
    return if (input < 0) -input else input;
}
