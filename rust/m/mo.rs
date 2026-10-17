const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_VALUE: i32 = 255;
const MAX_PARSEABLE_INPUT_WORDS: usize = 2 + MAX_N + 2 * MAX_Q + 1;

#[derive(Clone, Copy)]
struct Query { left: usize, right: usize, index: usize }

fn ceil_sqrt(n: usize) -> usize {
    let mut block = 1;
    while block * block < n { block += 1; }
    block
}

#[no_mangle]
pub unsafe extern "C" fn mo(input: *const i32, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_WORDS { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_raw = values[0];
    if n_raw < 1 || n_raw > MAX_N as i32 { return -1; }
    let n = n_raw as usize;
    let q_offset = 1 + n;
    if length <= q_offset { return -1; }
    let q_raw = values[q_offset];
    if q_raw < 0 || q_raw > MAX_Q as i32 { return -1; }
    let q_count = q_raw as usize;
    if length != q_offset + 1 + 2 * q_count { return -1; }
    if values[1..q_offset].iter().any(|&value| value < 0 || value > MAX_VALUE) { return -1; }

    let mut queries = [Query { left: 0, right: 0, index: 0 }; MAX_Q];
    for i in 0..q_count {
        let left = values[q_offset + 1 + 2 * i];
        let right = values[q_offset + 2 + 2 * i];
        if left < 1 || right < left || right > n as i32 { return -1; }
        queries[i] = Query { left: (left - 1) as usize, right: (right - 1) as usize, index: i };
    }
    let bytes = q_count * 4;
    if output.is_null() || capacity < bytes { return -2; }

    let block_size = ceil_sqrt(n);
    queries[..q_count].sort_unstable_by_key(|query| (query.left / block_size, query.right));
    let mut frequencies = [0i32; MAX_VALUE as usize + 1];
    let mut answers = [0i32; MAX_Q];
    let mut distinct = 0i32;
    let (mut left, mut right) = (0usize, 0usize);
    for query in &queries[..q_count] {
        while left < query.left {
            left += 1;
            let value = values[left] as usize;
            frequencies[value] -= 1;
            if frequencies[value] == 0 { distinct -= 1; }
        }
        while left > query.left {
            left -= 1;
            let value = values[1 + left] as usize;
            frequencies[value] += 1;
            if frequencies[value] == 1 { distinct += 1; }
        }
        while right <= query.right {
            let value = values[1 + right] as usize;
            frequencies[value] += 1;
            if frequencies[value] == 1 { distinct += 1; }
            right += 1;
        }
        while right > query.right + 1 {
            right -= 1;
            let value = values[1 + right] as usize;
            frequencies[value] -= 1;
            if frequencies[value] == 0 { distinct -= 1; }
        }
        answers[query.index] = distinct;
    }

    for i in 0..q_count { *output.add(4 * i) = answers[i].to_le_bytes()[0]; *output.add(4 * i + 1) = answers[i].to_le_bytes()[1]; *output.add(4 * i + 2) = answers[i].to_le_bytes()[2]; *output.add(4 * i + 3) = answers[i].to_le_bytes()[3]; }
    bytes as i64
}
