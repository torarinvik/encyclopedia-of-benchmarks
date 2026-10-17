const MAX_INPUT_LENGTH: usize = 130;
const MAX_OPERATIONS: usize = 64;
const MAX_LIST_LENGTH: usize = 64;
const MAX_OUTPUT_FIELDS: usize = 194;

fn append_i64(records: &mut [i64; MAX_OUTPUT_FIELDS], count: &mut usize, value: i64) {
    records[*count] = value;
    *count += 1;
}

fn execute(input: &[i64], records: &mut [i64; MAX_OUTPUT_FIELDS]) -> Result<usize, ()> {
    if input.is_empty() || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let operation_count = input[0];
    if !(0..=MAX_OPERATIONS as i64).contains(&operation_count)
        || input.len() != 1 + 2 * operation_count as usize { return Err(()); }

    let mut items = [0i64; MAX_LIST_LENGTH];
    let (mut item_count, mut record_count, mut cursor) = (0usize, 0usize, 1usize);
    for _ in 0..operation_count {
        let opcode = input[cursor];
        let value = input[cursor + 1];
        cursor += 2;
        if !(i32::MIN as i64..=i32::MAX as i64).contains(&value) { return Err(()); }
        if opcode == 0 {
            if item_count == MAX_LIST_LENGTH { return Err(()); }
            items[item_count] = value;
            item_count += 1;
            append_i64(records, &mut record_count, 0);
            append_i64(records, &mut record_count, 0);
        } else if opcode == 1 {
            let found_at = items[..item_count].iter().position(|&item| item == value);
            let found = i64::from(found_at.is_some());
            append_i64(records, &mut record_count, 1);
            append_i64(records, &mut record_count, 1);
            append_i64(records, &mut record_count, found);
            if let Some(index) = found_at {
                if index != 0 {
                    for position in (1..=index).rev() { items[position] = items[position - 1]; }
                    items[0] = value;
                }
            }
        } else {
            return Err(());
        }
    }
    append_i64(records, &mut record_count, 2);
    append_i64(records, &mut record_count, item_count as i64);
    for &value in &items[..item_count] { append_i64(records, &mut record_count, value); }
    Ok(record_count)
}

#[no_mangle]
pub unsafe extern "C" fn self_organizing_linked_list(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut records = [0i64; MAX_OUTPUT_FIELDS];
    let record_count = match execute(values, &mut records) { Ok(count) => count, Err(()) => return -1 };
    let output_bytes = record_count * 8;
    if output.is_null() || output_capacity < output_bytes { return -2; }
    for (index, record) in records[..record_count].iter().enumerate() {
        std::ptr::copy_nonoverlapping(record.to_le_bytes().as_ptr(), output.add(index * 8), 8);
    }
    output_bytes as i64
}
