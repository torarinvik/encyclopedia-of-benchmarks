export fn buzz_number(n: i64) i64 {
    if (@rem(n, 7) == 0) return 1;
    if (n >= 0 and @rem(n, 10) == 7) return 1;
    return 0;
}
