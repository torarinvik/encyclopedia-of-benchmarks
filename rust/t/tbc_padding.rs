const MAX_BYTES: usize = 256;

fn write_i64_le(output: &mut [u8], position: usize, value: i64) {
    output[position..position + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn tbc_padding(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_BYTES + 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let operation = values[0];
    let offset_value = values[1];
    let count_value = values[2];
    if !(0..=2).contains(&operation) || !(0..=MAX_BYTES as i64).contains(&count_value) ||
        length != count_value as usize + 3 { return -1; }
    let count = count_value as usize;
    if (operation == 0 && (count == 0 || offset_value < 0 || offset_value > count_value)) ||
        (operation != 0 && offset_value != 0) || (operation == 2 && count == 0) { return -1; }
    if values[3..].iter().any(|&byte| !(0..=255).contains(&byte)) { return -1; }

    if operation == 0 {
        let offset = offset_value as usize;
        let previous = values[if offset > 0 { offset + 2 } else { count + 2 }];
        let code = if (previous & 1) == 0 { 0xff } else { 0x00 };
        let needed = 8 + count;
        if output.is_null() || capacity < needed { return -2; }
        let out = std::slice::from_raw_parts_mut(output, needed);
        write_i64_le(out, 0, (count - offset) as i64);
        for index in 0..count { out[8 + index] = if index >= offset { code } else { values[3 + index] as u8 }; }
        return needed as i64;
    }
    if operation == 1 {
        let mut survivors = count;
        if count > 0 {
            let code = if (values[2 + count] & 1) == 0 { 0x00 } else { 0xff };
            while survivors > 0 && values[2 + survivors] == code { survivors -= 1; }
        }
        if output.is_null() || capacity < survivors { return -2; }
        let out = std::slice::from_raw_parts_mut(output, survivors);
        for index in 0..survivors { out[index] = values[3 + index] as u8; }
        return survivors as i64;
    }
    let terminal = values[2 + count];
    if terminal != 0 && terminal != 255 { return -1; }
    let mut padding_count = 0;
    while padding_count < count && values[2 + count - padding_count] == terminal { padding_count += 1; }
    if output.is_null() || capacity < 8 { return -2; }
    let out = std::slice::from_raw_parts_mut(output, 8);
    write_i64_le(out, 0, padding_count as i64);
    8
}
