module bell_numbers;

// Return the exact Bell number for indices that fit in signed 64-bit output.
fn long bell_numbers(long n) @export("bell_numbers") {
    if (n < 0 || n > 25) return -1;
    if (n == 0) return 1;

    long[26] row;
    row[0] = 1;
    for (long current = 1; current < n; current++) {
        long previous_first = row[0];
        long previous_last = row[current - 1];
        row[0] = previous_last;
        long previous_old = previous_first;
        for (long column = 1; column <= current; column++) {
            long old_value = column < current ? row[column] : 0;
            row[column] = row[column - 1] + previous_old;
            previous_old = old_value;
        }
    }
    return row[n - 1];
}
