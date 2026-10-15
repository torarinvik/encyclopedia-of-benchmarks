export fn max_number_of_balloons(text: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    var b: i64 = 0;
    var a: i64 = 0;
    var l: i64 = 0;
    var o: i64 = 0;
    var n: i64 = 0;
    var index: usize = 0;
    while (index < length) : (index += 1) {
        const value = text[index];
        if (value < 97 or value > 122) return -1;
        if (value == 98) b += 1
        else if (value == 97) a += 1
        else if (value == 108) l += 1
        else if (value == 111) o += 1
        else if (value == 110) n += 1;
    }
    l = @divTrunc(l, 2);
    o = @divTrunc(o, 2);
    var minimum = b;
    if (a < minimum) minimum = a;
    if (l < minimum) minimum = l;
    if (o < minimum) minimum = o;
    if (n < minimum) minimum = n;
    return minimum;
}
