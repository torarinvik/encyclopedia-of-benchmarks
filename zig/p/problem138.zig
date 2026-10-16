export fn problem138(count: i64) i64 {
    if (count > 14) return -1;
    if (count <= 0) return 0;
    var m: i64 = 2;
    var l: i64 = 1;
    var total: i64 = 0;
    var i: i64 = 0;
    while (i < count) : (i += 1) {
        const next_m = 9 * m + 20 * l;
        const next_l = 4 * m + 9 * l;
        m = next_m;
        l = next_l;
        total += l;
    }
    return total;
}
