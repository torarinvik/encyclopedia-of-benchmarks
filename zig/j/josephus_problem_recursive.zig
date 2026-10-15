fn josephus_solve(n: i64, step: i64) i64 {
    if (n == 1) return 0;
    return @mod(josephus_solve(n - 1, step) + @mod(step, n), n);
}
export fn josephus_problem_recursive(values: [*]const i64, length: usize) i64 {
    if (length != 2) return -1;
    const n = values[0];
    const step = values[1];
    if (n < 1 or n > 256 or step < 1) return -1;
    return josephus_solve(n, step) + 1;
}
