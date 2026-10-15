#[no_mangle]
pub extern "C" fn josephus_problem(values: *const i64, length: usize) -> i64 {
    if length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (n, step) = (values[0], values[1]);
    if n < 1 || n > 100000 || step < 1 { return -1; }
    let mut winner = 0i64;
    for size in 1..=n { winner = (winner + step % size) % size; }
    winner + 1
}
