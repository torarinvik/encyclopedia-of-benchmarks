const MAX_ITEMS: usize = 64;
const MAX_INPUT_WORDS: usize = 66;

#[no_mangle]
pub unsafe extern "C" fn blelloch_parallel_prefix_scan(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_WORDS).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    if !(1..=MAX_ITEMS as i64).contains(&n64) {
        return -1;
    }
    let n = n64 as usize;
    if length != n + 1 {
        return -1;
    }

    let mut tree = [0i64; MAX_ITEMS];
    let mut padded = 1usize;
    while padded < n {
        padded <<= 1;
    }
    for i in 0..n {
        let value = values[i + 1];
        if !(-1_000_000..=1_000_000).contains(&value) {
            return -1;
        }
        tree[i] = value;
    }
    if output.is_null() || output_capacity < n * 8 {
        return -2;
    }

    let mut stride = 2usize;
    while stride <= padded {
        let half = stride >> 1;
        let mut right = stride - 1;
        while right < padded {
            tree[right] += tree[right - half];
            right += stride;
        }
        stride <<= 1;
    }
    tree[padded - 1] = 0;
    stride = padded;
    while stride >= 2 {
        let half = stride >> 1;
        let mut right = stride - 1;
        while right < padded {
            let left = right - half;
            let partial = tree[left];
            tree[left] = tree[right];
            tree[right] += partial;
            right += stride;
        }
        stride >>= 1;
    }
    for (i, value) in tree[..n].iter().enumerate() {
        let bits = *value as u64;
        for byte in 0..8 {
            output.add(i * 8 + byte).write((bits >> (8 * byte)) as u8);
        }
    }
    (n * 8) as i64
}
