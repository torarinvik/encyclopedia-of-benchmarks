const MAX_BITS: usize = 4096;
const MAX_WORDS: usize = 64;
const MAX_OPERATIONS: usize = 64;

fn popcount64(mut value: u64) -> i32 {
    let mut count = 0;
    while value != 0 {
        value &= value - 1;
        count += 1;
    }
    count
}

unsafe fn store_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn bitset_xor_shift_trace(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 131 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let q_value = values[1];
    if n_value < 1 || n_value > MAX_BITS as i64 || q_value < 0 || q_value > MAX_OPERATIONS as i64 { return -1; }
    let n = n_value as usize;
    let q = q_value as usize;
    let word_count = (n + 63) / 64;
    let shift_offset = 2 + word_count;
    if length != shift_offset + q { return -1; }

    let mut words = [0u64; MAX_WORDS];
    for word in 0..word_count { words[word] = values[2 + word] as u64; }
    let tail_bits = n % 64;
    let tail_mask = if tail_bits == 0 { u64::MAX } else { (1u64 << tail_bits) - 1 };
    if words[word_count - 1] & !tail_mask != 0 { return -1; }
    for operation in 0..q {
        let shift = values[shift_offset + operation];
        if shift < -(n_value - 1) || shift > n_value - 1 { return -1; }
    }

    let output_bytes = q * 4;
    if output_bytes != 0 && (output.is_null() || capacity < output_bytes) { return -2; }
    let mut counts = [0i32; MAX_OPERATIONS];
    for operation in 0..q {
        let shift = values[shift_offset + operation];
        if shift == 0 {
            for word in 0..word_count { words[word] = 0; }
        } else if shift > 0 {
            let distance = shift as usize;
            let whole = distance / 64;
            let part = distance % 64;
            for destination in 0..word_count {
                let source = destination + whole;
                let mut shifted = if source < word_count { words[source] >> part } else { 0 };
                if part != 0 && source + 1 < word_count {
                    shifted |= words[source + 1] << (64 - part);
                }
                words[destination] ^= shifted;
            }
        } else {
            let distance = (-shift) as usize;
            let whole = distance / 64;
            let part = distance % 64;
            for destination in (0..word_count).rev() {
                let source = destination as isize - whole as isize;
                let mut shifted = if source >= 0 { words[source as usize] << part } else { 0 };
                if part != 0 && source > 0 { shifted |= words[source as usize - 1] >> (64 - part); }
                words[destination] ^= shifted;
            }
        }
        words[word_count - 1] &= tail_mask;
        let mut count = 0;
        for word in 0..word_count { count += popcount64(words[word]); }
        counts[operation] = count;
    }
    for operation in 0..q { store_i32_le(output, operation * 4, counts[operation]); }
    output_bytes as i64
}
