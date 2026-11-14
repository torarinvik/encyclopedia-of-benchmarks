#[no_mangle]
pub unsafe extern "C" fn walker_vose_alias_sampling(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=83).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=16).contains(&values[0]) || !(0..=32).contains(&values[1]) { return -1; }
    let n = values[0] as usize;
    let q = values[1] as usize;
    if length != 2 + n + 2 * q { return -1; }
    let weights = &values[2..2 + n];
    if weights.iter().any(|&w| !(0..=100).contains(&w)) { return -1; }
    let total: i64 = weights.iter().sum();
    if total == 0 { return -1; }
    let draws = &values[2 + n..];
    if draws.chunks_exact(2).any(|d| d[0] < 0 || d[0] >= n as i64 || d[1] < 0 || d[1] >= total) { return -1; }
    if q == 0 { return 0; }
    if output.is_null() || capacity < 8 * q { return -2; }

    let mut mass = [0i64; 16];
    let mut threshold = [total; 16];
    let mut alias = [0usize; 16];
    let mut small = Vec::with_capacity(n);
    let mut large = Vec::with_capacity(n);
    for i in 0..n {
        mass[i] = n as i64 * weights[i];
        alias[i] = i;
        if mass[i] < total { small.push(i); } else { large.push(i); }
    }
    while !small.is_empty() && !large.is_empty() {
        let low = small.pop().unwrap();
        let high = large.pop().unwrap();
        threshold[low] = mass[low];
        alias[low] = high;
        mass[high] -= total - mass[low];
        if mass[high] < total { small.push(high); } else { large.push(high); }
    }
    let mut staged = [0u8; 256];
    for (i, draw) in draws.chunks_exact(2).enumerate() {
        let column = draw[0] as usize;
        let result = if draw[1] < threshold[column] { column } else { alias[column] };
        staged[8 * i..8 * i + 8].copy_from_slice(&(result as i64).to_le_bytes());
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, 8 * q);
    (8 * q) as i64
}
