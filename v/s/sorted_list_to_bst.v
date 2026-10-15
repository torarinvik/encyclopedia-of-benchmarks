module sorted_list_to_bst

fn emit_tree(values &i64, start usize, end usize, output &u8, position usize) usize {
    if start == end { unsafe { output[position] = 0 }; return position + 1 }
    mut middle := start
    mut fast := start
    for fast < end && fast + 1 < end { fast += 2; middle++ }
    value := unsafe { values[middle] }
    unsafe { output[position] = 1 }
    encoded := if value < 0 { value + 4294967296 } else { value }
    unsafe {
        output[position + 1] = u8(encoded % 256)
        output[position + 2] = u8((encoded / 256) % 256)
        output[position + 3] = u8((encoded / 65536) % 256)
        output[position + 4] = u8(encoded / 16777216)
    }
    next_position := emit_tree(values, start, middle, output, position + 5)
    return emit_tree(values, middle + 1, end, output, next_position)
}

@[export: 'sorted_list_to_bst']
pub fn sorted_list_to_bst(values &i64, length usize, output &u8, output_capacity usize) i64 {
    if length > 64 { return -1 }
    for index in 0 .. length {
        value := unsafe { values[index] }
        if value < -2147483648 || value > 2147483647 { return -1 }
        if index > 0 && unsafe { values[index - 1] } > value { return -1 }
    }
    required := 6 * length + 1
    if output_capacity < required { return -2 }
    emit_tree(values, 0, length, output, 0)
    return i64(length)
}
