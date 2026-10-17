const MAX_KEYS: usize = 4;
const MAX_KEY_LENGTH: usize = 32;
const MAX_MESSAGE_LENGTH: usize = 256;
const MAX_INPUT_LENGTH: usize = 3 + MAX_KEYS + MAX_KEYS * MAX_KEY_LENGTH + MAX_MESSAGE_LENGTH;
const MAX_OUTPUT_LENGTH: usize = 2 * MAX_MESSAGE_LENGTH - 1;

fn normalize(input: &[u8], output: &mut [u8; MAX_MESSAGE_LENGTH]) -> usize {
    let mut count = 0;
    for &byte in input {
        let upper = if byte.is_ascii_lowercase() { byte - b'a' + b'A' } else { byte };
        if upper.is_ascii_uppercase() {
            output[count] = upper;
            count += 1;
        }
    }
    count
}

fn column_order(key: &[u8], key_length: usize, order: &mut [usize; MAX_KEY_LENGTH]) {
    for index in 0..key_length { order[index] = index; }
    for index in 1..key_length {
        let column = order[index];
        let mut position = index;
        while position > 0 && key[order[position - 1]] > key[column] {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = column;
    }
}

fn encrypt_round(text: &[u8], key: &[u8], key_length: usize,
                 output: &mut [u8; MAX_OUTPUT_LENGTH]) -> usize {
    let mut order = [0usize; MAX_KEY_LENGTH];
    let mut columns = [0u8; MAX_MESSAGE_LENGTH];
    column_order(key, key_length, &mut order);
    let mut ordered_length = 0;
    for rank in 0..key_length {
        let mut position = order[rank];
        while position < text.len() {
            columns[ordered_length] = text[position];
            ordered_length += 1;
            position += key_length;
        }
    }
    let group_size = (text.len() + key_length - 1) / key_length;
    let mut output_length = 0;
    for index in 0..ordered_length {
        output[output_length] = columns[index];
        output_length += 1;
        if (index + 1) % group_size == 0 && index + 1 < ordered_length {
            output[output_length] = b' ';
            output_length += 1;
        }
    }
    output_length
}

fn decrypt_round(text: &[u8], key: &[u8], key_length: usize,
                 output: &mut [u8; MAX_OUTPUT_LENGTH]) -> usize {
    let mut order = [0usize; MAX_KEY_LENGTH];
    let mut columns = [[0u8; MAX_MESSAGE_LENGTH]; MAX_KEY_LENGTH];
    let mut column_lengths = [0usize; MAX_KEY_LENGTH];
    column_order(key, key_length, &mut order);
    let short_length = text.len() / key_length;
    let longer_columns = text.len() % key_length;
    let mut cursor = 0;
    for rank in 0..key_length {
        let column = order[rank];
        let length = short_length + usize::from(column < longer_columns);
        column_lengths[column] = length;
        for row in 0..length {
            columns[column][row] = text[cursor];
            cursor += 1;
        }
    }
    let row_count = short_length + usize::from(longer_columns > 0);
    let mut output_length = 0;
    for row in 0..row_count {
        for column in 0..key_length {
            if row < column_lengths[column] {
                output[output_length] = columns[column][row];
                output_length += 1;
            }
        }
    }
    output_length
}

fn hash_output(text: &[u8]) -> i64 {
    let mut hash = 14_695_981_039_346_656_037u64;
    let mut feed = |byte: u8| {
        hash = (hash ^ u64::from(byte)).wrapping_mul(1_099_511_628_211);
    };
    for byte in (text.len() as u64).to_le_bytes() { feed(byte); }
    for &value in text {
        for byte in (value as u32).to_le_bytes() { feed(byte); }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}

#[no_mangle]
pub unsafe extern "C" fn transposition_rust(input_pointer: *const i64, length: usize) -> i64 {
    if input_pointer.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_pointer, length) };
    let mode = input[0];
    let key_count_value = input[1];
    if (mode != 0 && mode != 1) || !(1..=MAX_KEYS as i64).contains(&key_count_value) { return -1; }
    let key_count = key_count_value as usize;
    let mut keys = [[0u8; MAX_KEY_LENGTH]; MAX_KEYS];
    let mut key_lengths = [0usize; MAX_KEYS];
    let mut longest_key = 0usize;
    let mut cursor = 2usize;
    for key_index in 0..key_count {
        if cursor >= length { return -1; }
        let key_length_value = input[cursor];
        cursor += 1;
        if !(1..=MAX_KEY_LENGTH as i64).contains(&key_length_value) { return -1; }
        let key_length = key_length_value as usize;
        if key_length > length - cursor { return -1; }
        for index in 0..key_length {
            let value = input[cursor + index];
            if !((b'A' as i64..=b'Z' as i64).contains(&value) ||
                 (b'a' as i64..=b'z' as i64).contains(&value)) { return -1; }
            let byte = value as u8;
            keys[key_index][index] = if byte.is_ascii_lowercase() { byte - b'a' + b'A' } else { byte };
        }
        cursor += key_length;
        key_lengths[key_index] = key_length;
        longest_key = longest_key.max(key_length);
    }
    if cursor >= length { return -1; }
    let message_length_value = input[cursor];
    cursor += 1;
    if !(1..=MAX_MESSAGE_LENGTH as i64).contains(&message_length_value) { return -1; }
    let message_length = message_length_value as usize;
    if message_length != length - cursor { return -1; }
    let mut message = [0u8; MAX_MESSAGE_LENGTH];
    for index in 0..message_length {
        let value = input[cursor + index];
        if !(0..=127).contains(&value) { return -1; }
        message[index] = value as u8;
    }

    let mut current = [0u8; MAX_OUTPUT_LENGTH];
    let mut filtered = [0u8; MAX_MESSAGE_LENGTH];
    let mut next = [0u8; MAX_OUTPUT_LENGTH];
    let mut current_length = normalize(&message[..message_length], &mut filtered);
    if current_length < longest_key { return -1; }
    current[..current_length].copy_from_slice(&filtered[..current_length]);
    for pass in 0..key_count {
        let key_index = if mode == 0 { pass } else { key_count - 1 - pass };
        let filtered_length = normalize(&current[..current_length], &mut filtered);
        let next_length = if mode == 0 {
            encrypt_round(&filtered[..filtered_length], &keys[key_index][..key_lengths[key_index]],
                          key_lengths[key_index], &mut next)
        } else {
            decrypt_round(&filtered[..filtered_length], &keys[key_index][..key_lengths[key_index]],
                          key_lengths[key_index], &mut next)
        };
        current[..next_length].copy_from_slice(&next[..next_length]);
        current_length = next_length;
    }
    hash_output(&current[..current_length])
}
