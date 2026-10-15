export fn pell_number(index: i64) i64 {
    if (index < 0 or index > 50) return -1;
    if (index == 0) return 0;
    var previous: i64 = 0;
    var current: i64 = 1;
    var i: i64 = 2;
    while (i <= index) : (i += 1) {
        const next = 2 * current + previous;
        previous = current;
        current = next;
    }
    return current;
}
