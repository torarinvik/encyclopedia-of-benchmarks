export fn tetranacci_numbers_sequence(index: i64) i64 {
    if (index < 0 or index > 68) return -1;
    var a: i64 = 1;
    var b: i64 = 1;
    var c: i64 = 1;
    var d: i64 = 1;
    if (index <= 3) return 1;
    var i: i64 = 4;
    while (i <= index) : (i += 1) {
        const next = a + b + c + d;
        a = b;
        b = c;
        c = d;
        d = next;
    }
    return d;
}
