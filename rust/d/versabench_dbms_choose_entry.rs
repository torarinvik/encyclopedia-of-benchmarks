fn valid_box(v: &[i64], at: usize) -> bool {
    for d in 0..4 {
        if !(-8..=8).contains(&v[at + d]) || !(-8..=8).contains(&v[at + 4 + d]) || v[at + d] >= v[at + 4 + d] { return false; }
    }
    true
}
fn volume_at(v: &[i64], at: usize) -> i64 {
    let mut result = 1;
    for d in 0..4 { result *= v[at + 4 + d] - v[at + d]; }
    result
}
fn penalty_at(v: &[i64], child: usize, incoming: usize) -> i64 {
    let mut joined_volume = 1;
    for d in 0..4 {
        let lo = v[child + d].min(v[incoming + d]);
        let hi = v[child + 4 + d].max(v[incoming + 4 + d]);
        joined_volume *= hi - lo;
    }
    joined_volume - volume_at(v, child)
}

#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_choose_entry(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length < 1 || length > 74 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(raw, length) };
    if !(1..=8).contains(&values[0]) { return -1; }
    let count = values[0] as usize;
    if length != 1 + 8 * count + 8 { return -1; }
    let incoming = 1 + 8 * count;
    for i in 0..count { if !valid_box(values, 1 + 8 * i) { return -1; } }
    if !valid_box(values, incoming) { return -1; }
    let mut best = 0;
    let mut best_penalty = penalty_at(values, 1, incoming);
    for i in 1..count {
        let candidate = penalty_at(values, 1 + 8 * i, incoming);
        if candidate < best_penalty { best = i; best_penalty = candidate; }
    }
    best as i64
}
