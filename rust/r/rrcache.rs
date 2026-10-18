const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 3 + 3 * MAX_OPERATIONS;
const JAVA_MULTIPLIER: u64 = 0x5DEECE66D;
const JAVA_ADDEND: u64 = 0xB;
const JAVA_MASK: u64 = (1u64 << 48) - 1;

fn java_next_bits(state: &mut u64, bits: u32) -> u32 {
    *state = state.wrapping_mul(JAVA_MULTIPLIER).wrapping_add(JAVA_ADDEND) & JAVA_MASK;
    (*state >> (48 - bits)) as u32
}

fn java_next_int(state: &mut u64, bound: u32) -> u32 {
    if bound & (bound - 1) == 0 {
        return ((bound as u64 * java_next_bits(state, 31) as u64) >> 31) as u32;
    }
    loop {
        let bits = java_next_bits(state, 31);
        let value = bits % bound;
        if bits as u64 - value as u64 + (bound - 1) as u64 <= i32::MAX as u64 {
            return value;
        }
    }
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn rrcache(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=8).contains(&values[0]) || !(0..=MAX_OPERATIONS as i64).contains(&values[2]) { return -1; }
    let cache_capacity = values[0] as usize;
    let operation_count = values[2] as usize;
    if length != 3 + 3 * operation_count { return -1; }

    let mut keys = [0i64; 8];
    let mut cache_values = [0i64; 8];
    let mut results = [0i64; MAX_OPERATIONS];
    let mut size = 0usize;
    let mut random_state = (values[1] as u64 ^ JAVA_MULTIPLIER) & JAVA_MASK;

    for operation in 0..operation_count {
        let offset = 3 + 3 * operation;
        let opcode = values[offset];
        let key = values[offset + 1];
        let value = values[offset + 2];
        if opcode == 0 {
            if !(1..=1024).contains(&key) || !(100..=1_000_000).contains(&value) { return -1; }
            let mut index = 0usize;
            while index < size && keys[index] != key { index += 1; }
            if index < size {
                cache_values[index] = value;
            } else {
                if size == cache_capacity {
                    let evicted = java_next_int(&mut random_state, size as u32) as usize;
                    for movement in evicted..size - 1 {
                        keys[movement] = keys[movement + 1];
                        cache_values[movement] = cache_values[movement + 1];
                    }
                    size -= 1;
                }
                keys[size] = key;
                cache_values[size] = value;
                size += 1;
            }
            results[operation] = -2;
        } else if opcode == 1 {
            if !(1..=1024).contains(&key) || value != 0 { return -1; }
            let mut index = 0usize;
            while index < size && keys[index] != key { index += 1; }
            results[operation] = if index < size { cache_values[index] } else { -1 };
        } else if opcode == 2 {
            if key != 0 || value != 0 { return -1; }
            results[operation] = size as i64;
        } else { return -1; }
    }

    let output_bytes = operation_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OPERATIONS * 8];
    for operation in 0..operation_count { put_i64_le(&mut staged, operation * 8, results[operation]); }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
