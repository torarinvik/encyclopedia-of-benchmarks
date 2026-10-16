fn put_i64(out: &mut [u8], offset: usize, value: i64) { out[offset..offset + 8].copy_from_slice(&value.to_le_bytes()); }
fn put_f64(out: &mut [u8], offset: usize, value: f64) { out[offset..offset + 8].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn similarity_search(input: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 643 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (rv, qv, fv) = (values[0], values[1], values[2]);
    if !(1..=32).contains(&rv) || !(1..=8).contains(&qv) || !(1..=16).contains(&fv) { return -1; }
    let (rows, queries, features) = (rv as usize, qv as usize, fv as usize);
    if length != 3 + (rows + queries) * features { return -1; }
    if values[3..].iter().any(|&v| !(-1_000_000..=1_000_000).contains(&v)) { return -1; }
    let record = 16 + 8 * features;
    let needed = queries * record;
    if output.is_null() || output_capacity < needed { return -2; }
    let out = unsafe { std::slice::from_raw_parts_mut(output, needed) };
    for query in 0..queries {
        let mut best = 0usize;
        let mut sum = 0.0f64;
        for f in 0..features {
            let delta = values[3 + f] as f64 / 1_000_000.0 -
                values[3 + rows * features + query * features + f] as f64 / 1_000_000.0;
            sum += delta * delta;
        }
        let mut best_distance = sum.sqrt();
        for row in 1..rows {
            sum = 0.0;
            for f in 0..features {
                let delta = values[3 + row * features + f] as f64 / 1_000_000.0 -
                    values[3 + rows * features + query * features + f] as f64 / 1_000_000.0;
                sum += delta * delta;
            }
            let distance = sum.sqrt();
            if distance < best_distance { best = row; best_distance = distance; }
        }
        let base = query * record;
        put_i64(out, base, best as i64);
        put_f64(out, base + 8, best_distance);
        for f in 0..features { put_i64(out, base + 16 + 8 * f, values[3 + best * features + f]); }
    }
    needed as i64
}
