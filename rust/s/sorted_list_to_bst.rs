/// Build a height-balanced BST from a sorted linked-list value sequence and serialize it.
fn emit_tree(values: &[i64], output: *mut u8, start: usize, end: usize, position: usize) -> usize {
    if start == end {
        unsafe { output.add(position).write(0); }
        return position + 1;
    }
    let mut middle = start;
    let mut fast = start;
    while fast < end && fast + 1 < end { fast += 2; middle += 1; }
    unsafe {
        output.add(position).write(1);
        let encoded = values[middle] as i32 as u32;
        output.add(position + 1).write(encoded as u8);
        output.add(position + 2).write((encoded >> 8) as u8);
        output.add(position + 3).write((encoded >> 16) as u8);
        output.add(position + 4).write((encoded >> 24) as u8);
    }
    let next_position = emit_tree(values, output, start, middle, position + 5);
    emit_tree(values, output, middle + 1, end, next_position)
}

#[no_mangle]
pub extern "C" fn sorted_list_to_bst(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length > 64 { return -1; }
    if length > 0 {
        let values = unsafe { std::slice::from_raw_parts(values, length) };
        if values.iter().any(|&value| !(-2147483648..=2147483647).contains(&value)) ||
            values.windows(2).any(|pair| pair[0] > pair[1]) { return -1; }
    }
    let required = 6 * length + 1;
    if output_capacity < required || output.is_null() { return -2; }
    if length == 0 {
        unsafe { output.write(0); }
        return 0;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    emit_tree(values, output, 0, length, 0);
    length as i64
}
