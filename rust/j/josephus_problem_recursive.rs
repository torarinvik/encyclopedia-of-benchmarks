fn josephus_solve(n: i64, step: i64) -> i64 {
    if n == 1 { return 0; }
    (josephus_solve(n - 1, step) + step % n) % n
}
#[no_mangle]
pub extern "C" fn josephus_problem_recursive(values: *const i64, length: usize) -> i64 {
    if length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (n, step) = (values[0], values[1]);
    if n < 1 || n > 256 || step < 1 { return -1; }
    josephus_solve(n, step) + 1
}
