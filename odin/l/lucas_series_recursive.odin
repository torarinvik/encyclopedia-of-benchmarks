package lucas_series_recursive
solve :: proc "contextless" (n: i64) -> i64 {
    if n == 0 do return 2
    if n == 1 do return 1
    return solve(n - 1) + solve(n - 2)
}
@(export)
lucas_series_recursive :: proc "c" (n: i64) -> i64 {
    if n < 0 || n > 25 do return -1
    return solve(n)
}
