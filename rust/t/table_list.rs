const MAX_INPUT_LENGTH: usize = 98;
const MAX_OUTPUT_FIELDS: usize = 594;
const MIN_VALUE: i64 = -1_000_000;
const MAX_VALUE: i64 = 1_000_000;

fn append(records: &mut [i64; MAX_OUTPUT_FIELDS], count: &mut usize, value: i64) {
    records[*count] = value;
    *count += 1;
}

fn execute(input: &[i64], records: &mut [i64; MAX_OUTPUT_FIELDS]) -> Result<usize, ()> {
    if input.is_empty() || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let operation_count = input[0];
    if !(0..=32).contains(&operation_count) || input.len() != 1 + 3 * operation_count as usize { return Err(()); }
    let mut items = [0i64; 64];
    let (mut head, mut item_count, mut record_count, mut cursor) = (32usize, 0usize, 0usize, 1usize);
    for _ in 0..operation_count {
        let opcode = input[cursor];
        let arg1 = input[cursor + 1];
        let arg2 = input[cursor + 2];
        cursor += 3;
        match opcode {
            0 | 1 => {
                if !(MIN_VALUE..=MAX_VALUE).contains(&arg1) || arg2 != 0 || item_count >= 32 { return Err(()); }
                if opcode == 0 { head -= 1; items[head] = arg1; } else { items[head + item_count] = arg1; }
                item_count += 1;
                append(records, &mut record_count, opcode); append(records, &mut record_count, 0);
            }
            2 => {
                if arg1 != 0 || arg2 != 0 { return Err(()); }
                append(records, &mut record_count, opcode);
                if item_count == 0 { append(records, &mut record_count, 0); }
                else { append(records, &mut record_count, 1); append(records, &mut record_count, items[head]); head += 1; item_count -= 1; }
            }
            3 => {
                if arg1 != 0 || arg2 != 0 { return Err(()); }
                append(records, &mut record_count, opcode);
                if item_count == 0 { append(records, &mut record_count, 0); }
                else { append(records, &mut record_count, 1); item_count -= 1; append(records, &mut record_count, items[head + item_count]); }
            }
            4 | 5 => {
                if arg1 != 0 || arg2 != 0 { return Err(()); }
                append(records, &mut record_count, opcode);
                if item_count == 0 { append(records, &mut record_count, 0); }
                else { append(records, &mut record_count, 1); append(records, &mut record_count, if opcode == 4 { items[head] } else { items[head + item_count - 1] }); }
            }
            6 => {
                if arg2 != 0 || arg1 < 1 || arg1 as u64 > item_count as u64 { return Err(()); }
                append(records, &mut record_count, opcode); append(records, &mut record_count, 1);
                append(records, &mut record_count, items[head + arg1 as usize - 1]);
            }
            7 => {
                if arg1 < 1 || arg1 as u64 > item_count as u64 || !(MIN_VALUE..=MAX_VALUE).contains(&arg2) { return Err(()); }
                items[head + arg1 as usize - 1] = arg2;
                append(records, &mut record_count, opcode); append(records, &mut record_count, 0);
            }
            8 => {
                if !(-1..=33).contains(&arg1) || arg2 != 0 { return Err(()); }
                append(records, &mut record_count, opcode); append(records, &mut record_count, 1);
                append(records, &mut record_count, if arg1 >= 1 && arg1 as u64 <= item_count as u64 { 1 } else { 0 });
            }
            9 => {
                if arg1 != 0 || arg2 != 0 { return Err(()); }
                append(records, &mut record_count, opcode); append(records, &mut record_count, 1); append(records, &mut record_count, item_count as i64);
            }
            10 | 11 => {
                if arg1 != 0 || arg2 != 0 { return Err(()); }
                append(records, &mut record_count, opcode); append(records, &mut record_count, item_count as i64);
                for offset in 0..item_count {
                    let logical = if opcode == 10 { offset + 1 } else { item_count - offset };
                    append(records, &mut record_count, logical as i64);
                    append(records, &mut record_count, items[head + logical - 1]);
                }
            }
            _ => return Err(()),
        }
    }
    append(records, &mut record_count, 12); append(records, &mut record_count, item_count as i64);
    for offset in 0..item_count { append(records, &mut record_count, items[head + offset]); }
    Ok(record_count)
}

#[no_mangle]
pub unsafe extern "C" fn table_list(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut records = [0i64; MAX_OUTPUT_FIELDS];
    let count = match execute(values, &mut records) { Ok(count) => count, Err(()) => return -1 };
    let bytes = count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for index in 0..count { std::ptr::copy_nonoverlapping(records[index].to_le_bytes().as_ptr(), output.add(index * 8), 8); }
    bytes as i64
}
