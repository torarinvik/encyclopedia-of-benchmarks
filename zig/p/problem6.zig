export fn problem6(limit: i64) i64 {
    if (limit < 0 or limit > 100) return -1;
    var sum: i64 = 0;
    var sum_of_squares: i64 = 0;
    var value: i64 = 1;
    while (value <= limit) : (value += 1) {
        sum += value;
        sum_of_squares += value * value;
    }
    return sum * sum - sum_of_squares;
}
