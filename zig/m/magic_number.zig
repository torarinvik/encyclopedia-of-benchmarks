/// Positive n is magic when its decimal digit root is one.
export fn magic_number(n: i64) i64 {
    if (n > 0 and @mod(n, 9) == 1) return 1;
    return 0;
}
