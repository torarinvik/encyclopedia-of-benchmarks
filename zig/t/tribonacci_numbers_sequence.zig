/// Zero-based Tribonacci sequence with source seeds 1, 1, 1.
export fn tribonacci_numbers_sequence(index: i64) i64 {
    if (index < 0 or index > 60) return -1;
    if (index < 3) return 1;

    var first: i64 = 1;
    var second: i64 = 1;
    var third: i64 = 1;
    var i: i64 = 3;
    while (i <= index) : (i += 1) {
        const next = first + second + third;
        first = second;
        second = third;
        third = next;
    }
    return third;
}
