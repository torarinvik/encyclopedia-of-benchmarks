package problem014

collatz_length :: proc(start: u64) -> u64 {
    current := start
    length := u64(1)
    for current != 1 {
        if length >= 10_000 do return 0
        if current % 2 == 0 {
            current /= 2
        } else {
            if current > 3_002_399_751_580_330 do return 0
            current = 3 * current + 1
        }
        length += 1
    }
    return length
}

@(export)
problem014 :: proc "c" (limit: i64) -> i64 {
    if limit < 1 || limit > 1_000_000 do return -1
    best_start := u64(1)
    best_length := u64(1)
    for start := u64(2); start < u64(limit); start += 1 {
        length := collatz_length(start)
        if length == 0 do return -1
        if length > best_length {
            best_start = start
            best_length = length
        }
    }
    return i64(best_start)
}
