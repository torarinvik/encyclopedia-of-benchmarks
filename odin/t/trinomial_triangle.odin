package trinomial_triangle

trinomial_value :: proc(n, k: i64) -> i64 {
    if n == 0 && k == 0 do return 1
    if k < -n || k > n do return 0
    return trinomial_value(n - 1, k - 1) +
           trinomial_value(n - 1, k) +
           trinomial_value(n - 1, k + 1)
}

@(export)
trinomial_triangle :: proc "c" (n, k: i64) -> i64 {
    if n < 0 || n > 10 || k < -10 || k > 10 do return -1
    return trinomial_value(n, k)
}
