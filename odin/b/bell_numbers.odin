package bell_numbers

// Return the exact Bell number for indices that fit in signed 64-bit output.
@(export)
bell_numbers :: proc "c" (n: i64) -> i64 {
    if n < 0 || n > 25 do return -1
    if n == 0 do return 1

    row: [26]i64 = {}
    row[0] = 1
    for current := 1; current < int(n); current += 1 {
        previous_first := row[0]
        previous_last := row[current - 1]
        row[0] = previous_last
        previous_old := previous_first
        for column := 1; column <= current; column += 1 {
            old_value := i64(0)
            if column < current do old_value = row[column]
            row[column] = row[column - 1] + previous_old
            previous_old = old_value
        }
    }
    return row[int(n) - 1]
}
