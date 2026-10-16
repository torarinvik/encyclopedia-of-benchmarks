const MAX_N: usize = 128;

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn coordinate_compression(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 {
        return -1;
    }
    let packed = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_N as i64).contains(&packed[0]) {
        return -1;
    }
    let n = packed[0] as usize;
    if length != n + 1 || packed[1..].iter().any(|v| *v < i32::MIN as i64 || *v > i32::MAX as i64) {
        return -1;
    }
    if capacity < n * 8 || (n > 0 && output.is_null()) {
        return -2;
    }
    if n == 0 {
        return 0;
    }
    let mut sorted = [0i64; MAX_N];
    sorted[..n].copy_from_slice(&packed[1..]);
    sorted[..n].sort_unstable();
    let mut ranks = [0i64; MAX_N];
    let mut rank = -1i64;
    for i in 0..n {
        if i == 0 || sorted[i] != sorted[i - 1] { rank += 1; }
        ranks[i] = rank;
    }
    let out = std::slice::from_raw_parts_mut(output, n * 8);
    for (i, value) in packed[1..].iter().enumerate() {
        let index = sorted[..n].binary_search(value).unwrap_or_else(|index| index);
        put_i64_le(out, i * 8, ranks[index]);
    }
    (n * 8) as i64
}
