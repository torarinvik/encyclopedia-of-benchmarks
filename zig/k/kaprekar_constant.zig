fn kaprekarStep(number: i64) i64 {
    var d0 = @divTrunc(number, 1000);
    var d1 = @mod(@divTrunc(number, 100), 10);
    var d2 = @mod(@divTrunc(number, 10), 10);
    var d3 = @mod(number, 10);
    var temp: i64 = 0;

    if (d0 > d1) { temp = d0; d0 = d1; d1 = temp; }
    if (d2 > d3) { temp = d2; d2 = d3; d3 = temp; }
    if (d0 > d2) { temp = d0; d0 = d2; d2 = temp; }
    if (d1 > d3) { temp = d1; d1 = d3; d3 = temp; }
    if (d1 > d2) { temp = d1; d1 = d2; d2 = temp; }

    const ascending = d0 * 1000 + d1 * 100 + d2 * 10 + d3;
    const descending = d3 * 1000 + d2 * 100 + d1 * 10 + d0;
    return descending - ascending;
}

export fn kaprekar_constant(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length != 2) return -1;
    const input = values.?[0..length];
    const number = input[0];
    const max_iterations = input[1];
    if (number < 0 or number > 9999 or max_iterations < 1 or max_iterations > 16) return -1;
    if (number == 6174) return 0;

    var current = number;
    var iteration: i64 = 1;
    while (iteration <= max_iterations) : (iteration += 1) {
        current = kaprekarStep(current);
        if (current == 6174) return iteration;
        if (current == 0) return -1;
    }
    return -1;
}
