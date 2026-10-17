export fn multiple_of_3_or_5_term(n: i64) i64 {
    if (n < 0 or n > 1000000000) return -1;
    return if (@rem(n, 3) == 0 or @rem(n, 5) == 0) n else 0;
}
