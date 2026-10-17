export fn so1(threshold: i64) i64 {
    if (threshold < -2_147_483_648 or threshold > 1_000_000_000) return -1;

    var first: i64 = 1;
    var second: i64 = 2;
    var total: i64 = 0;
    while (second <= threshold) {
        if (@rem(second, 2) == 0) total += second;
        const temporary = first;
        first = second;
        second = temporary + first;
    }
    return total;
}
