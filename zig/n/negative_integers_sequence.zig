export fn negative_integers_sequence(index: i64) i64 {
    if (index < 0) return 0;
    return -index - 1;
}
