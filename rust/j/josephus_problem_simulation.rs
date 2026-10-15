#[no_mangle]
pub extern "C" fn josephus_problem_simulation(values: *const i64, length: usize) -> i64 {
    if length != 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (n, step) = (values[0], values[1]);
    if n < 1 || n > 512 || step < 1 { return -1; }
    let mut people = [0i64; 512];
    let mut remaining = n as usize;
    for i in 0..remaining { people[i] = i as i64 + 1; }
    let mut current = 0usize;
    while remaining > 1 {
        let offset = ((step - 1) % remaining as i64) as usize;
        let removed = (current + offset) % remaining;
        for i in removed..remaining - 1 { people[i] = people[i + 1]; }
        remaining -= 1;
        current = removed % remaining;
    }
    people[0]
}
