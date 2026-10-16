package problem138

@(export)
problem138 :: proc "c" (count: i64) -> i64 {
    if count > 14 do return -1
    if count <= 0 do return 0
    m := i64(2)
    l := i64(1)
    total := i64(0)
    for i := i64(0); i < count; i += 1 {
        next_m := 9 * m + 20 * l
        next_l := 4 * m + 9 * l
        m = next_m
        l = next_l
        total += l
    }
    return total
}
