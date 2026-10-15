const MAX_INDEX: i64 = 3_037_000_499;

export fn squares_sequence(index: i64) i64 {
    if (index < 0 or index > MAX_INDEX) return -1;
    return index * index;
}
