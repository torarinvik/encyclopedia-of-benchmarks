export fn problem2(limit: i64) i64 {
    if (limit < 0 or limit > 4_000_000) return -1;
    var previous: i64 = 1;
    var current: i64 = 2;
    var total: i64 = 0;
    while (current < limit) {
        if (@rem(current, 2) == 0) total += current;
        const next = previous + current;
        previous = current;
        current = next;
    }
    return total;
}
