const MAX_OPERATIONS: usize = 512;
const MAX_COLLECTION_SIZE: usize = 256;
const MAX_VALID_INPUT_LENGTH: usize = 1024;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1025;

fn search_position(values: &[i64; MAX_COLLECTION_SIZE], count: usize, target: i64) -> (usize, bool) {
    let mut left = 0;
    let mut right = count;
    while right > left {
        let middle = (left + right) / 2;
        if target > values[middle] { left = middle + 1; }
        else if target < values[middle] { right = middle; }
        else { return (middle, true); }
    }
    (left, false)
}

#[no_mangle]
pub unsafe extern "C" fn sorted_list_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() { return if length == 0 { 0 } else { -1 }; }
    if length > MAX_PARSEABLE_INPUT_LENGTH || length % 2 != 0 || length > MAX_VALID_INPUT_LENGTH { return -1; }
    let input_values = std::slice::from_raw_parts(input, length);
    let operation_count = length / 2;
    if operation_count > MAX_OPERATIONS { return -1; }
    let mut values = [0_i64; MAX_COLLECTION_SIZE];
    let mut count = 0_usize;
    let mut checksum = 0_i64;
    for operation in 0..operation_count {
        let opcode = input_values[2 * operation];
        let payload = input_values[2 * operation + 1];
        if !(0..=5).contains(&opcode) { return -1; }
        if opcode == 0 {
            if !(0..=1_000_000).contains(&payload) || count >= MAX_COLLECTION_SIZE { return -1; }
            let (position, _) = search_position(&values, count, payload);
            for index in (position..count).rev() { values[index + 1] = values[index]; }
            values[position] = payload;
            count += 1;
        } else if opcode == 1 || opcode == 2 {
            if !(0..=1_000_000).contains(&payload) { return -1; }
            let (position, found) = search_position(&values, count, payload);
            let observed = if found { 1_i64 } else { 0_i64 };
            if opcode == 2 && found {
                for index in position..count - 1 { values[index] = values[index + 1]; }
                count -= 1;
            }
            checksum += (operation as i64 + 1) * (observed + 1_000_000);
        } else if opcode == 3 {
            if payload != 0 { return -1; }
            checksum += (operation as i64 + 1) * (count as i64 + 1_000_000);
        } else if opcode == 4 {
            if payload < 0 || payload >= count as i64 { return -1; }
            checksum += (operation as i64 + 1) * (values[payload as usize] + 1_000_000);
        } else {
            if payload != 0 { return -1; }
            count = 0;
        }
    }
    for index in 0..count {
        checksum += (operation_count as i64 + index as i64 + 1) * (values[index] + 1_000_000);
    }
    checksum
}
