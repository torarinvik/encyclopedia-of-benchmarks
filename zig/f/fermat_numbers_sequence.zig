export fn fermat_numbers_sequence(index: i64) i64 {
    if (index < 0 or index > 5) return -1;
    var value: i64 = 2;
    var i: i64 = 0;
    while (i < index) : (i += 1) {
        value *= value;
    }
    return value + 1;
}
