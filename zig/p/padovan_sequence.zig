export fn padovan_sequence(index: i64) i64 {
    if (index < 0 or index > 156) return -1;
    if (index <= 2) return 1;

    var a: i64 = 1;
    var b: i64 = 1;
    var c: i64 = 1;
    var result: i64 = 0;
    var i: i64 = 3;
    while (i <= index) : (i += 1) {
        result = a + b;
        a = b;
        b = c;
        c = result;
    }
    return result;
}
