const MAX_OPERATIONS: usize = 128;
const MAX_CAPACITY: usize = 16;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_OPERATIONS + 1;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;

fn hash_responses(responses: &[i32]) -> i64 {
    let mut hash = FNV_OFFSET;
    for byte in (responses.len() as u16).to_le_bytes() {
        hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
    }
    for response in responses {
        for byte in response.to_le_bytes() {
            hash = (hash ^ u64::from(byte)).wrapping_mul(FNV_PRIME);
        }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let capacity64 = input[0];
    let operation_count64 = input[1];
    if !(1..=MAX_CAPACITY as i64).contains(&capacity64)
        || !(0..=MAX_OPERATIONS as i64).contains(&operation_count64)
        || input.len() != 2 + 3 * operation_count64 as usize { return Err(()); }
    let capacity = capacity64 as usize;
    let operation_count = operation_count64 as usize;
    let mut keys = [0i32; MAX_CAPACITY];
    let mut values = [0i32; MAX_CAPACITY];
    let mut responses = [0i32; MAX_OPERATIONS];
    let (mut cache_count, mut response_count) = (0usize, 0usize);

    for step in 0..operation_count {
        let operation = input[2 + 3 * step];
        let key64 = input[3 + 3 * step];
        let value64 = input[4 + 3 * step];
        if !(0..=1).contains(&operation)
            || key64 < i32::MIN as i64 || key64 > i32::MAX as i64
            || value64 < i32::MIN as i64 || value64 > i32::MAX as i64 { return Err(()); }
        let key = key64 as i32;
        let value = value64 as i32;
        let mut position = 0usize;
        while position < cache_count && keys[position] != key { position += 1; }

        if operation == 0 {
            if !(0..=1_000_000).contains(&value) { return Err(()); }
            if position < cache_count {
                for index in position..(cache_count - 1) {
                    keys[index] = keys[index + 1];
                    values[index] = values[index + 1];
                }
                keys[cache_count - 1] = key;
                values[cache_count - 1] = value;
            } else {
                if cache_count == capacity { cache_count -= 1; }
                keys[cache_count] = key;
                values[cache_count] = value;
                cache_count += 1;
            }
        } else if position == cache_count {
            responses[response_count] = -1;
            response_count += 1;
        } else {
            let response = values[position];
            for index in position..(cache_count - 1) {
                keys[index] = keys[index + 1];
                values[index] = values[index + 1];
            }
            keys[cache_count - 1] = key;
            values[cache_count - 1] = response;
            responses[response_count] = response;
            response_count += 1;
        }
    }
    Ok(hash_responses(&responses[..response_count]))
}

#[no_mangle]
pub unsafe extern "C" fn mrucache(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    execute(values).unwrap_or(-1)
}
