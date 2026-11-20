const MAX_PAIRS: usize = 10;
const MAX_INPUT_LENGTH: usize = 21;
const MAX_OUTPUT_BYTES: usize = 20;

#[no_mangle]
pub unsafe extern "C" fn balanced_parenthesis_successor(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_PAIRS as i64 { return -1; }
    let pairs = values[0] as usize;
    let sequence_length = 2 * pairs;
    if length != 1 + sequence_length { return -1; }
    let mut symbols = [0u8; MAX_OUTPUT_BYTES];
    let mut balance = 0i32;
    for i in 0..sequence_length {
        let symbol = values[1 + i];
        if symbol != 0 && symbol != 1 { return -1; }
        symbols[i] = symbol as u8;
        balance += if symbol == 0 { 1 } else { -1 };
        if balance < 0 { return -1; }
    }
    if balance != 0 { return -1; }
    if output.is_null() || capacity < sequence_length { return -2; }

    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    let mut reverse_depth = 0i32;
    let mut cursor = sequence_length;
    while cursor > 0 {
        cursor -= 1;
        let i = cursor;
        if symbols[i] == 0 { reverse_depth -= 1; } else { reverse_depth += 1; }
        if symbols[i] == 0 && reverse_depth > 0 {
            reverse_depth -= 1;
            let suffix_length = sequence_length - i - 1;
            let opening_count = ((suffix_length as i32 - reverse_depth) / 2) as usize;
            let closing_count = suffix_length - opening_count;
            for j in 0..i { staged[j] = if symbols[j] == 0 { b'(' } else { b')' }; }
            staged[i] = b')';
            let mut position = i + 1;
            for _ in 0..opening_count { staged[position] = b'('; position += 1; }
            for _ in 0..closing_count { staged[position] = b')'; position += 1; }
            for j in 0..sequence_length { *output.add(j) = staged[j]; }
            return sequence_length as i64;
        }
    }
    -3
}
