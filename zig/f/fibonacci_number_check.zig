/// Check the Fibonacci square identity without overflowing signed 64-bit values.
fn square_i64(value: i64) bool {
    if (value < 0) return false;
    var low: i64 = 0;
    var high: i64 = 3037000499;
    while (low <= high) {
        const middle = low + @divTrunc(high - low, 2);
        const square = middle * middle;
        if (square == value) return true;
        if (square < value) low = middle + 1 else high = middle - 1;
    }
    return false;
}

export fn fibonacci_number_check(number: i64) i64 {
    if (number < -1300000000 or number > 1300000000) return -1;
    const value = 5 * number * number;
    return if (square_i64(value + 4) or square_i64(value - 4)) 1 else 0;
}
