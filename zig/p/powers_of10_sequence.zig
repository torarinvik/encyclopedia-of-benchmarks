export fn powers_of10_sequence(index: i64) i64 {
    if (index < 0 or index > 18) return -1;
    var value: i64 = 1;
    var i: i64 = 0;
    while (i < index) : (i += 1) value *= 10;
    return value;
}
