fn between(ids: &[i64], ring: i64, left: usize, item: usize, right: usize) -> bool {
    let distance = (ids[item]-ids[left]+ring)%ring;
    let span = (ids[right]-ids[left]+ring)%ring;
    distance > 0 && (span == 0 || distance < span)
}

#[no_mangle]
pub unsafe extern "C" fn chord_stabilization_trace(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(6..=115).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=6).contains(&values[0]) || !(1..=16).contains(&values[1]) || !(0..=64).contains(&values[2]) { return -1; }
    let ring = 1i64 << values[0]; let n = values[1] as usize; let q = values[2] as usize;
    if n > ring as usize || length != 3+3*n+q { return -1; }
    let ids = &values[3..3+n];
    if ids.iter().any(|&id| id < 0 || id >= ring) || ids.windows(2).any(|pair| pair[0] >= pair[1]) { return -1; }
    let mut succ = [0usize; 16]; let mut pred = [-1i64; 16];
    for i in 0..n {
        let s = values[3+n+i]; let p = values[3+2*n+i];
        if s < 0 || s >= n as i64 || p < -1 || p >= n as i64 { return -1; }
        succ[i] = s as usize; pred[i] = p;
    }
    let schedule = &values[3+3*n..];
    if schedule.iter().any(|&v| v < 0 || v >= n as i64) { return -1; }
    for &v in schedule {
        let node = v as usize; let candidate = pred[succ[node]];
        if candidate >= 0 && between(ids, ring, node, candidate as usize, succ[node]) { succ[node] = candidate as usize; }
        let receiver = succ[node];
        if pred[receiver] < 0 || between(ids, ring, pred[receiver] as usize, node, receiver) { pred[receiver] = node as i64; }
    }
    if output.is_null() || capacity < 2*n { return -2; }
    let out = std::slice::from_raw_parts_mut(output, 2*n);
    for i in 0..n { out[i] = succ[i] as u8; out[n+i] = if pred[i] < 0 { 255 } else { pred[i] as u8 }; }
    (2*n) as i64
}
