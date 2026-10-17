const MAX_N: usize = 256;
const MAX_Q: usize = 256;
const MAX_INPUT_LENGTH: usize = 4 + MAX_N + 3 * MAX_Q + 1;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn query_before(a: usize, b: usize, lefts: &[i32; MAX_Q], rights: &[i32; MAX_Q], block_size: usize) -> bool {
    let block_a = lefts[a] / block_size as i32;
    let block_b = lefts[b] / block_size as i32;
    if block_a != block_b { return block_a < block_b; }
    if block_a & 1 != 0 { rights[a] < rights[b] } else { rights[a] > rights[b] }
}

fn hash_results(operation: u8, count: usize, results: &[i32]) -> i64 {
    let mut hash = FNV_OFFSET;
    for byte in [operation, (count as u16).to_le_bytes()[0], (count as u16).to_le_bytes()[1]] {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    for result in results {
        for byte in result.to_le_bytes() { hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME); }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 4 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let operation = input[0];
    let n64 = input[1];
    let q64 = input[2];
    let target64 = input[3];
    if !(0..=1).contains(&operation) || !(1..=MAX_N as i64).contains(&n64)
        || !(0..=MAX_Q as i64).contains(&q64) || !(-1_000_000..=1_000_000).contains(&target64)
        || input.len() != 4 + n64 as usize + 3 * q64 as usize { return Err(()); }
    let n = n64 as usize;
    let q = q64 as usize;
    let target = target64 as i32;
    let mut values = [0i32; MAX_N];
    for index in 0..n {
        if !(-1_000_000..=1_000_000).contains(&input[4 + index]) { return Err(()); }
        values[index] = input[4 + index] as i32;
    }

    let mut lefts = [0i32; MAX_Q];
    let mut rights = [0i32; MAX_Q];
    let mut indices = [0i32; MAX_Q];
    let mut order = [0usize; MAX_Q];
    let mut seen = [false; MAX_Q];
    let offset = 4 + n;
    for query in 0..q {
        let left = input[offset + 3 * query];
        let right = input[offset + 3 * query + 1];
        let index = input[offset + 3 * query + 2];
        if left < 0 || right < left || right >= n64 || index < 0 || index >= q64 || seen[index as usize] { return Err(()); }
        lefts[query] = left as i32;
        rights[query] = right as i32;
        indices[query] = index as i32;
        seen[index as usize] = true;
        order[query] = query;
    }

    let mut block_size = 1usize;
    while (block_size + 1) * (block_size + 1) <= n { block_size += 1; }
    for query in 1..q {
        let current = order[query];
        let mut position = query;
        while position > 0 && query_before(current, order[position - 1], &lefts, &rights, block_size) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }

    let mut results = [0i32; MAX_Q];
    let (mut current_left, mut current_right, mut aggregate) = (0i32, -1i32, 0i32);
    for sorted in 0..q {
        let query = order[sorted];
        let (left, right) = (lefts[query], rights[query]);
        if operation == 0 {
            while current_right < right { current_right += 1; aggregate += values[current_right as usize]; }
            while current_right > right { aggregate -= values[current_right as usize]; current_right -= 1; }
            while current_left < left { aggregate -= values[current_left as usize]; current_left += 1; }
            while current_left > left { current_left -= 1; aggregate += values[current_left as usize]; }
        } else {
            while current_right < right { current_right += 1; if values[current_right as usize] == target { aggregate += 1; } }
            while current_right > right { if values[current_right as usize] == target { aggregate -= 1; } current_right -= 1; }
            while current_left < left { if values[current_left as usize] == target { aggregate -= 1; } current_left += 1; }
            while current_left > left { current_left -= 1; if values[current_left as usize] == target { aggregate += 1; } }
        }
        results[indices[query] as usize] = aggregate;
    }
    Ok(hash_results(operation as u8, q, &results[..q]))
}

#[no_mangle]
pub unsafe extern "C" fn mos_algorithm(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
