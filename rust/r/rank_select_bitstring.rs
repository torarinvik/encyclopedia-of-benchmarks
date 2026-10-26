const MAX_BITS: usize = 63;
const MAX_BLOCKS: usize = 8;
const MAX_QUERIES: usize = 16;
const MAX_INPUT: usize = 35;
const MAX_OUTPUT_BYTES: usize = 128;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn rank_select_bitstring(input: *const i64, length: usize,
                                                output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let packed_value = values[1];
    let query_value = values[2];
    if n_value < 1 || n_value > MAX_BITS as i64 || packed_value < 0 || query_value < 0 || query_value > MAX_QUERIES as i64 { return -1; }
    let n = n_value as usize;
    let queries = query_value as usize;
    let bits = packed_value as u64;
    if bits >> n != 0 || length != 3 + 2 * queries { return -1; }
    let block_count = (n + 7) / 8;
    let mut prefix = [0i64; MAX_BLOCKS + 1];
    for block in 0..block_count {
        prefix[block + 1] = prefix[block];
        let end = (8 * block + 8).min(n);
        for pos in 8 * block..end { prefix[block + 1] += ((bits >> pos) & 1) as i64; }
    }
    let mut answers = [0i64; MAX_QUERIES];
    for query in 0..queries {
        let op = values[3 + 2 * query];
        let index_value = values[4 + 2 * query];
        if (op != 0 && op != 1) || index_value < 1 ||
            (if op == 0 { index_value > n_value } else { index_value > (MAX_BITS + 1) as i64 }) { return -1; }
        let index = index_value as usize;
        if op == 0 {
            let full_blocks = index / 8;
            let remainder = index % 8;
            let mut answer = prefix[full_blocks];
            for pos in 8 * full_blocks..8 * full_blocks + remainder { answer += ((bits >> pos) & 1) as i64; }
            answers[query] = answer;
        } else {
            let mut block = 0;
            while block < block_count && prefix[block + 1] < index as i64 { block += 1; }
            answers[query] = -1;
            if block < block_count {
                let mut remaining = index - prefix[block] as usize;
                let end = (8 * block + 8).min(n);
                for pos in 8 * block..end {
                    if (bits >> pos) & 1 != 0 {
                        remaining -= 1;
                        if remaining == 0 { answers[query] = pos as i64 + 1; break; }
                    }
                }
            }
        }
    }
    let output_bytes = 8 * queries;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for query in 0..queries { store_i64_le(staged.as_mut_ptr(), 8 * query, answers[query]); }
    for byte in 0..output_bytes { *output.add(byte) = staged[byte]; }
    output_bytes as i64
}
