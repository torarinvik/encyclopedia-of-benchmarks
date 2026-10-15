package josephus_problem_recursive
import "core:c"
josephus_solve :: proc "contextless" (n, step: i64) -> i64 {
    if n == 1 do return 0
    return (josephus_solve(n - 1, step) + step % n) % n
}
@(export)
josephus_problem_recursive :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length != 2 do return -1
    n := values[0]
    step := values[1]
    if n < 1 || n > 256 || step < 1 do return -1
    return josephus_solve(n, step) + 1
}
