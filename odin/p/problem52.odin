package problem52

same_digits :: proc(left, right: i64) -> bool {
    a: [10]int
    b: [10]int
    x, y := left, right
    for x > 0 { a[x % 10] += 1; x /= 10 }
    for y > 0 { b[y % 10] += 1; y /= 10 }
    return a == b
}

@(export)
problem52 :: proc "c" (unused: i64) -> i64 {
    if unused != 0 do return -1
    for value := i64(1);; value += 1 {
        matches := true
        for multiplier := i64(2); multiplier <= 6 && matches; multiplier += 1 {
            matches = same_digits(value, multiplier*value)
        }
        if matches do return value
    }
}
