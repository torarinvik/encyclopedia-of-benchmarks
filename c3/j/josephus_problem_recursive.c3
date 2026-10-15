module josephus_problem_recursive;
fn long josephus_solve(long n, long step) {
    if (n == 1) return 0;
    return (josephus_solve(n - 1, step) + step % n) % n;
}
fn long josephus_problem_recursive(long* values, usz length) @export("josephus_problem_recursive") {
    if (length != 2) return -1;
    long n = values[0];
    long step = values[1];
    if (n < 1 || n > 256 || step < 1) return -1;
    return josephus_solve(n, step) + 1;
}
