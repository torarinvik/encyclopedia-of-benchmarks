package josephus_problem
import "core:c"
@(export)
josephus_problem :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length != 2 do return -1
    n := values[0]
    step := values[1]
    if n < 1 || n > 100000 || step < 1 do return -1
    winner := i64(0)
    for size := i64(1); size <= n; size += 1 {
        winner = (winner + step % size) % size
    }
    return winner + 1
}
