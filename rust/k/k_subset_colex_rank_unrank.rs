const MAX_N: usize = 16;
const MAX_K: usize = 16;

fn choose_small(n: usize, k: usize) -> i64 {
    if k > n { return 0; }
    let reduced = k.min(n - k);
    let mut value = 1i64;
    for i in 1..=reduced { value = value * (n - reduced + i) as i64 / i as i64; }
    value
}

fn store_i64_le(output: &mut [u8], index: usize, value: i64) {
    let bytes = value.to_le_bytes();
    output[index * 8..index * 8 + 8].copy_from_slice(&bytes);
}

fn run(values: &[i64]) -> Result<([i64; MAX_K], usize, i64), i64> {
    let mode = values[0];
    if (mode != 0 && mode != 1) || values.len() < 3 { return Err(-1); }
    let raw_n = values[1];
    let raw_k = values[2];
    if raw_n < 0 || raw_n > MAX_N as i64 || raw_k < 0 || raw_k > raw_n { return Err(-1); }
    let n = raw_n as usize;
    let k = raw_k as usize;
    let mut indices = [0i64; MAX_K];
    let rank;

    if mode == 0 {
        if values.len() != 3 + k { return Err(-1); }
        for i in 0..k {
            let index = values[3 + i];
            if index < 0 || index >= raw_n || (i > 0 && indices[i - 1] >= index) { return Err(-1); }
            indices[i] = index;
        }
        let mut total = 0i64;
        for i in 0..k { total += choose_small(indices[i] as usize, i + 1); }
        rank = total;
    } else {
        if values.len() != 4 { return Err(-1); }
        rank = values[3];
        if rank < 0 || rank >= choose_small(n, k) { return Err(-1); }
        let mut upper = n as i64 - 1;
        let mut remainder = rank;
        for order in (1..=k).rev() {
            let mut candidate = upper;
            while candidate >= 0 && choose_small(candidate as usize, order) > remainder { candidate -= 1; }
            if candidate < 0 { return Err(-1); }
            indices[order - 1] = candidate;
            remainder -= choose_small(candidate as usize, order);
            upper = candidate - 1;
        }
    }
    Ok((indices, k, rank))
}

#[no_mangle]
pub unsafe extern "C" fn k_subset_colex_rank_unrank(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=20).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (indices, k, rank) = match run(values) { Ok(result) => result, Err(code) => return code };
    let needed = (k + 1) * 8;
    if output.is_null() || capacity < needed { return -2; }
    let destination = unsafe { std::slice::from_raw_parts_mut(output, needed) };
    store_i64_le(destination, 0, rank);
    for i in 0..k { store_i64_le(destination, i + 1, indices[i]); }
    needed as i64
}
