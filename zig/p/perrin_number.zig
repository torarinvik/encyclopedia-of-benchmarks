export fn perrin_number(index: i64) i64 {
    if (index < 0 or index > 155) return -1;
    if (index == 0) return 3;
    if (index == 1) return 0;
    if (index == 2) return 2;
    var a: i64 = 3;
    var b: i64 = 0;
    var c: i64 = 2;
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
