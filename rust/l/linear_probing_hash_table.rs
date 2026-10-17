const MAX_TABLE_CAPACITY: usize = 128;
const MAX_OPERATIONS: usize = 32;
const MAX_INPUT_LENGTH: usize = 66;
const MAX_OUTPUT_WORDS: usize = 1088;
const MAX_KEY: i64 = i32::MAX as i64 - 127;

fn find_slot(table: &[i32; MAX_TABLE_CAPACITY], capacity: usize, key: i32) -> Option<usize> {
    let mut index = key as usize % capacity;
    for _ in 0..capacity {
        if table[index] == 0 { return None; }
        if table[index] == key { return Some(index); }
        index = (index + 1) % capacity;
    }
    None
}

fn insertion_slot(table: &[i32; MAX_TABLE_CAPACITY], capacity: usize, key: i32) -> Option<usize> {
    let mut index = key as usize % capacity;
    for _ in 0..capacity {
        if table[index] == 0 || table[index] == -1 { return Some(index); }
        index = (index + 1) % capacity;
    }
    None
}

fn rehash(table: &mut [i32; MAX_TABLE_CAPACITY], capacity: &mut usize) {
    let old_table = *table;
    let old_capacity = *capacity;
    *capacity *= 2;
    table[..*capacity].fill(0);
    for key in old_table[..old_capacity].iter().copied().filter(|key| *key > 0) {
        if let Some(slot) = insertion_slot(table, *capacity, key) { table[slot] = key; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn linear_probing_hash_table(input: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 2 || values[0] > 16 || values[1] < 0 || values[1] > MAX_OPERATIONS as i64 { return -1; }
    let mut table = [0i32; MAX_TABLE_CAPACITY];
    let mut table_capacity = values[0] as usize;
    let operation_count = values[1] as usize;
    let mut size = 0usize;
    let mut words = [0i64; MAX_OUTPUT_WORDS];
    let mut word_count = 0usize;
    let mut position = 2usize;
    for _ in 0..operation_count {
        if position >= length { return -1; }
        let opcode = values[position]; position += 1;
        if (0..=3).contains(&opcode) {
            if position >= length { return -1; }
            let key_arg = values[position]; position += 1;
            if !(1..=MAX_KEY).contains(&key_arg) { return -1; }
            let key = key_arg as i32;
            if opcode == 0 {
                let Some(slot) = insertion_slot(&table, table_capacity, key) else { return -1; };
                table[slot] = key; size += 1;
                words[word_count] = 0; words[word_count + 1] = 1; word_count += 2;
                if size * 2 >= table_capacity { rehash(&mut table, &mut table_capacity); }
            } else if opcode == 1 {
                let Some(slot) = find_slot(&table, table_capacity, key) else { return -1; };
                table[slot] = -1; size -= 1;
                words[word_count] = 1; words[word_count + 1] = 1; word_count += 2;
            } else if opcode == 2 {
                words[word_count] = 2;
                words[word_count + 1] = if find_slot(&table, table_capacity, key).is_some() { 1 } else { 0 };
                word_count += 2;
            } else {
                words[word_count] = 3; words[word_count + 1] = key as i64; word_count += 2;
            }
        } else if opcode == 4 {
            words[word_count] = 4; words[word_count + 1] = table_capacity as i64; word_count += 2;
            for slot in &table[..table_capacity] {
                words[word_count] = if *slot == 0 { -2 } else { *slot as i64 };
                word_count += 1;
            }
        } else { return -1; }
    }
    if position != length || word_count > MAX_OUTPUT_WORDS { return -1; }
    let output_length = word_count * 8;
    if output.is_null() || output_capacity < output_length { return -2; }
    for (i, word) in words[..word_count].iter().enumerate() {
        std::ptr::copy_nonoverlapping(word.to_le_bytes().as_ptr(), output.add(8 * i), 8);
    }
    output_length as i64
}
