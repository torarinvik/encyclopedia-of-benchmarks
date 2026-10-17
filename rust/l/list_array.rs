const MAX_CAPACITY: usize = 16;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_OPERATIONS;
const MAX_OUTPUT_WORDS: usize = 65;

fn selection_sort(items: &mut [u64; MAX_CAPACITY], count: usize) {
    for i in 0..count {
        let mut minimum = i;
        for j in i + 1..count {
            if items[j] < items[minimum] { minimum = j; }
        }
        items.swap(minimum, i);
    }
}

fn binary_search(items: &[u64; MAX_CAPACITY], first: usize, last: usize, value: u64) -> i64 {
    if last < first { return -1; }
    let middle = (first + last) / 2;
    if items[middle] == value { return middle as i64; }
    if value < items[middle] { return binary_search(items, first, middle - 1, value); }
    binary_search(items, middle + 1, last, value)
}

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    for (i, byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(offset + i) = *byte;
    }
}

#[no_mangle]
pub unsafe extern "C" fn list_array(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let capacity_value = input[0];
    let operation_count_value = input[1];
    if !(1..=MAX_CAPACITY as i64).contains(&capacity_value)
        || !(1..=MAX_OPERATIONS as i64).contains(&operation_count_value) { return -1; }
    let capacity = capacity_value as usize;
    let operations = operation_count_value as usize;
    if length != 2 + 2 * operations { return -1; }

    let mut opcodes = [0i64; MAX_OPERATIONS];
    let mut arguments = [0i64; MAX_OPERATIONS];
    let mut sorted = false;
    for i in 0..operations {
        let opcode = input[2 + 2 * i];
        let argument = input[3 + 2 * i];
        if opcode == 0 {
            if sorted || argument < 0 { return -1; }
        } else if opcode == 1 {
            if sorted || argument != 0 { return -1; }
            sorted = true;
        } else if opcode == 2 || opcode == 3 {
            if !sorted || argument < 0 { return -1; }
        } else { return -1; }
        opcodes[i] = opcode;
        arguments[i] = argument;
    }
    if !sorted { return -1; }

    let mut items = [0u64; MAX_CAPACITY];
    let mut results = [0i64; MAX_OPERATIONS];
    let mut output_words = [0i64; MAX_OUTPUT_WORDS];
    let mut count = 0usize;
    let mut result_count = 0usize;
    for i in 0..operations {
        let opcode = opcodes[i];
        let argument = arguments[i];
        if opcode == 0 {
            if count == capacity { return -1; }
            items[count] = argument as u64;
            count += 1;
        } else if opcode == 1 {
            selection_sort(&mut items, count);
        } else {
            if count == 0 || (argument as u64) < items[0] { return -1; }
            if opcode == 3 && count >= capacity { return -1; }
            let position = binary_search(&items, 0, count - 1, argument as u64);
            results[result_count] = position;
            result_count += 1;
            if opcode == 3 && position >= 0 {
                let mut j = position as usize;
                while j < count { items[j] = items[j + 1]; j += 1; }
                count -= 1;
            }
        }
    }

    let mut word_count = 0usize;
    output_words[word_count] = result_count as i64;
    word_count += 1;
    for i in 0..result_count { output_words[word_count] = results[i]; word_count += 1; }
    output_words[word_count] = count as i64;
    word_count += 1;
    for i in 0..count { output_words[word_count] = items[i] as i64; word_count += 1; }
    let required = word_count * 8;
    if output.is_null() || output_capacity < required { return -2; }
    for i in 0..word_count { put_i64_le(output, i * 8, output_words[i]); }
    required as i64
}
