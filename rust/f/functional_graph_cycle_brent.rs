#[no_mangle]
pub unsafe extern "C" fn functional_graph_cycle_brent(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=67).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n, start) = (values[0], values[1]);
    if !(1..=64).contains(&n) || start < 0 || start >= n || length != n as usize + 2
        || values[2..].iter().any(|&v| v < 0 || v >= n) { return -1; }
    let next = |v: usize| values[v + 2] as usize;
    let start = start as usize;
    let (mut checkpoint, mut moving) = (start, next(start));
    let (mut power, mut period) = (1usize, 1usize);
    while checkpoint != moving {
        if power == period { checkpoint = moving; power *= 2; period = 0; }
        moving = next(moving);
        period += 1;
    }
    let (mut left, mut right) = (start, start);
    for _ in 0..period { right = next(right); }
    let mut tail = 0;
    while left != right { left = next(left); right = next(right); tail += 1; }
    (65 * tail + period) as i64
}
