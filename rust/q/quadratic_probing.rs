const MIN_CAPACITY: usize = 5;
const MAX_CAPACITY: usize = 31;
const MAX_INSERT_COUNT: usize = 3;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 5;
const MAX_OUTPUT_BYTES: usize = 256;

#[no_mangle]
pub unsafe extern "C" fn quadratic_probing(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let capacity_value = values[0];
    let count_value = values[1];
    if !(MIN_CAPACITY as i64..=MAX_CAPACITY as i64).contains(&capacity_value)
        || !(0..=MAX_INSERT_COUNT as i64).contains(&count_value) { return -1; }
    let capacity = capacity_value as usize;
    let insert_count = count_value as usize;
    if input_length != 2 + insert_count { return -1; }
    for &key in &values[2..] {
        if key < 0 { return -1; }
    }

    let mut slots = [-1_i64; MAX_CAPACITY];
    for &key in &values[2..] {
        let home = (key % capacity as i64) as usize;
        if slots[home] == -1 {
            slots[home] = key;
            continue;
        }
        if slots[home] == key { continue; }

        let mut visited = [false; MAX_CAPACITY];
        let mut probe = 1_usize;
        loop {
            let slot = (home + probe * probe) % capacity;
            if slots[slot] == -1 || slots[slot] == home as i64 {
                slots[slot] = key;
                break;
            }
            if visited[slot] { return -1; }
            visited[slot] = true;
            probe += 1;
        }
    }

    let byte_length = 8 * (capacity + 1);
    if byte_length > MAX_OUTPUT_BYTES || output.is_null() || output_capacity < byte_length { return -2; }
    let mut words = [0_i64; MAX_CAPACITY + 1];
    words[0] = capacity as i64;
    words[1..=capacity].copy_from_slice(&slots[..capacity]);
    for (word_index, word) in words[..=capacity].iter().enumerate() {
        let bytes = word.to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(word_index * 8), 8);
    }
    byte_length as i64
}
