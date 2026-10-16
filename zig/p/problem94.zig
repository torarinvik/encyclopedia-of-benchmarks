export fn problem94(max_perimeter: i64) i64 {
    if (max_perimeter < 0 or max_perimeter > 1_000_000_000) return -1;
    var previous: i64 = 1;
    var value: i64 = 2;
    var perimeter_sum: i64 = 0;
    var index: i64 = 0;
    var perimeter: i64 = 0;
    while (perimeter <= max_perimeter) {
        perimeter_sum += perimeter;
        previous += 2 * value;
        value += previous;
        perimeter = if (@mod(index, 2) == 0) 2 * value + 2 else 2 * value - 2;
        index += 1;
    }
    return perimeter_sum;
}
