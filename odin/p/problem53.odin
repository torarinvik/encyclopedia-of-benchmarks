package problem53

@(export)
problem53 :: proc "c" (unused: i64) -> i64 {
    if unused != 0 do return -1
    total := i64(0)
    for n := 1; n <= 100; n += 1 {
        coefficient := i64(1)
        for r := 1; r <= n/2; r += 1 {
            coefficient = coefficient * i64(n-r+1) / i64(r)
            if coefficient > 1_000_000 { total += i64(n-2*r+1); break }
        }
    }
    return total
}
