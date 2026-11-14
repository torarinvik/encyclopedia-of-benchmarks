fn cross(p: &[(i64, i64); 32], a: usize, b: usize, c: usize) -> i64 {
    (p[b].0-p[a].0)*(p[c].1-p[a].1) - (p[b].1-p[a].1)*(p[c].0-p[a].0)
}

#[no_mangle]
pub unsafe extern "C" fn melkman_simple_polyline_hull(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(7..=66).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(3..=32).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != 1 + 2*n { return -1; }
    let mut points = [(0i64, 0i64); 32];
    for i in 0..n {
        points[i] = (values[1+2*i], values[2+2*i]);
        if !(-1000..=1000).contains(&points[i].0) || !(-1000..=1000).contains(&points[i].1) { return -1; }
    }
    let initial = cross(&points, 0, 1, 2);
    if initial == 0 { return -1; }
    let mut deque = [0usize; 68];
    let (mut first, mut last) = (32usize, 35usize);
    deque[32] = 2; deque[35] = 2;
    deque[33] = if initial > 0 { 0 } else { 1 };
    deque[34] = if initial > 0 { 1 } else { 0 };
    for i in 3..n {
        if cross(&points, deque[first], deque[first+1], i) > 0 &&
           cross(&points, deque[last-1], deque[last], i) > 0 { continue; }
        while last > first && cross(&points, deque[first], deque[first+1], i) <= 0 { first += 1; }
        if last <= first || first == 0 { return -1; }
        first -= 1; deque[first] = i;
        while last > first && cross(&points, deque[last-1], deque[last], i) <= 0 { last -= 1; }
        if last <= first || last + 1 >= deque.len() { return -1; }
        last += 1; deque[last] = i;
    }
    let count = last-first;
    let mut start = 0;
    for i in 1..count {
        if points[deque[first+i]] < points[deque[first+start]] { start = i; }
    }
    let bytes = 8*count;
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; 256];
    for i in 0..count {
        let index = deque[first + (start+i)%count] as i64;
        staged[8*i..8*i+8].copy_from_slice(&index.to_le_bytes());
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
