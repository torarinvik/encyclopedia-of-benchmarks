/// Duplicate each zero while retaining the fixed output length.
fn write_i32(output: *mut u8, position: usize, value: i64) {
    let encoded = value as i32 as u32;
    unsafe {
        output.add(position).write(encoded as u8);
        output.add(position + 1).write((encoded >> 8) as u8);
        output.add(position + 2).write((encoded >> 16) as u8);
        output.add(position + 3).write((encoded >> 24) as u8);
    }
}

#[no_mangle]
pub extern "C" fn duplicate_zeros(values: *const i64, length: usize,
                                   output: *mut u8, output_capacity: usize) -> i64 {
    if length > 64 { return -1; }
    if length > 0 {
        let values = unsafe { std::slice::from_raw_parts(values, length) };
        if values.iter().any(|&value| !(0..=1000).contains(&value)) { return -1; }
    }
    let required = 4 * length;
    if output_capacity < required || (required > 0 && output.is_null()) { return -2; }
    let values = if length == 0 { &[][..] } else { unsafe { std::slice::from_raw_parts(values, length) } };
    let mut source = 0;
    let mut destination = 0;
    while destination < length {
        let value = values[source];
        source += 1;
        write_i32(output, 4 * destination, value);
        destination += 1;
        if value == 0 && destination < length {
            write_i32(output, 4 * destination, 0);
            destination += 1;
        }
    }
    length as i64
}
