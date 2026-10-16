package problem112

is_bouncy :: proc(value: i64) -> bool {
    increasing := false
    decreasing := false
    previous := value % 10
    current := value / 10
    for current > 0 {
        digit := current % 10
        if digit < previous { increasing = true }
        if digit > previous { decreasing = true }
        previous = digit
        current /= 10
    }
    return increasing && decreasing
}

@(export)
problem112 :: proc "c" (percent: i64) -> i64 {
    if percent < 1 || percent > 99 do return -1
    bouncy := i64(0)
    n := i64(1)
    for {
        if is_bouncy(n) { bouncy += 1 }
        if bouncy * 100 >= percent * n do return n
        n += 1
    }
}
