package nth_ugly_number

// Return the zero-based 5-smooth number at index n.
@(export)
nth_ugly_number :: proc "c" (n: i64) -> i64 {
    if n < 0 || n > 12690 do return -1
    values: [12691]i64
    values[0] = 1
    i2, i3, i5 := 0, 0, 0
    for index := 1; index <= int(n); index += 1 {
        c2 := 2 * values[i2]
        c3 := 3 * values[i3]
        c5 := 5 * values[i5]
        next := min(c2, c3)
        if c5 < next do next = c5
        values[index] = next
        if c2 == next do i2 += 1
        if c3 == next do i3 += 1
        if c5 == next do i5 += 1
    }
    return values[int(n)]
}
