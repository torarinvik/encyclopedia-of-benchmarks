#[no_mangle]
pub unsafe extern "C" fn celebrity_finder(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -2; }
    let a = std::slice::from_raw_parts(input, length);
    if a[0] < 1 || a[0] > 64 { return -2; }
    let n = a[0] as usize;
    if length != 1 + n * n || a[1..].iter().any(|&v| v != 0 && v != 1) { return -2; }
    let mut stack = Vec::with_capacity(n);
    stack.extend(0..n);
    while stack.len() > 1 {
        let person1 = stack.pop().unwrap();
        let person2 = stack.pop().unwrap();
        stack.push(if a[1 + person1 * n + person2] == 1 { person2 } else { person1 });
    }
    let candidate = stack[0];
    for i in 0..n {
        if i != candidate && (a[1 + candidate * n + i] == 1 || a[1 + i * n + candidate] == 0) { return -1; }
    }
    candidate as i64
}
