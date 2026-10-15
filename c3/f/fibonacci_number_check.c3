module fibonacci_number_check;

fn bool square_i64(long value) {
    if (value < 0) return false;
    long low = 0;
    long high = 3037000499;
    while (low <= high) {
        long middle = low + (high - low) / 2;
        long square = middle * middle;
        if (square == value) return true;
        if (square < value) low = middle + 1;
        else high = middle - 1;
    }
    return false;
}

fn long fibonacci_number_check(long number) @export("fibonacci_number_check") {
    if (number < -1300000000 || number > 1300000000) return -1;
    long value = 5 * number * number;
    return square_i64(value + 4) || square_i64(value - 4) ? 1 : 0;
}
