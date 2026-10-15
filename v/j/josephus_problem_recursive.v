module josephus_problem_recursive
fn josephus_solve(n i64, step i64) i64 {
    if n == 1 { return 0 }
    return (josephus_solve(n - 1, step) + step % n) % n
}
@[export: 'josephus_problem_recursive']
pub fn josephus_problem_recursive(values &i64, length usize) i64 {
    if length != 2 { return -1 }
    n := unsafe { values[0] }
    step := unsafe { values[1] }
    if n < 1 || n > 256 || step < 1 { return -1 }
    return josephus_solve(n, step) + 1
}
