const MAX_NODES: usize = 127;

fn decimal_length(value: i64) -> usize {
    let mut magnitude = if value < 0 { -value } else { value };
    let mut length = if value < 0 { 1 } else { 0 };
    loop {
        length += 1;
        magnitude /= 10;
        if magnitude == 0 { return length; }
    }
}

unsafe fn append_value(value: i32, output: *mut u8, position: &mut usize) {
    let mut magnitude = if value < 0 { -(value as i64) as u64 } else { value as u64 };
    let mut digits = [0_u8; 10];
    let mut count = 0;
    if value < 0 { *output.add(*position) = b'-'; *position += 1; }
    loop {
        digits[count] = b'0' + (magnitude % 10) as u8;
        count += 1;
        magnitude /= 10;
        if magnitude == 0 { break; }
    }
    while count > 0 { count -= 1; *output.add(*position) = digits[count]; *position += 1; }
}

unsafe fn emit_node(values: *const i64, index: usize, output: *mut u8, position: &mut usize) {
    let base = 2 + 3 * index;
    let left = *values.add(base + 1);
    let right = *values.add(base + 2);
    append_value(*values.add(base) as i32, output, position);
    if left >= 0 {
        *output.add(*position) = b'('; *position += 1;
        emit_node(values, left as usize, output, position);
        *output.add(*position) = b')'; *position += 1;
    } else if right >= 0 {
        *output.add(*position) = b'('; *position += 1;
        *output.add(*position) = b')'; *position += 1;
    }
    if right >= 0 {
        *output.add(*position) = b'('; *position += 1;
        emit_node(values, right as usize, output, position);
        *output.add(*position) = b')'; *position += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn binary_tree_to_string(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 2 { return -1; }
    let count_value = *values;
    if count_value < 0 || count_value > MAX_NODES as i64 { return -1; }
    let count = count_value as usize;
    if length != 2 + 3 * count { return -1; }
    let root_value = *values.add(1);
    if count == 0 { return if root_value == -1 { 0 } else { -1 }; }
    if root_value < 0 || root_value as u64 >= count as u64 { return -1; }
    let root = root_value as usize;
    let mut parents = [0_u8; MAX_NODES];
    let mut seen = [false; MAX_NODES];
    let mut stack = [0_usize; MAX_NODES];
    for i in 0..count {
        let base = 2 + 3 * i;
        let value = *values.add(base);
        let left = *values.add(base + 1);
        let right = *values.add(base + 2);
        if value < i32::MIN as i64 || value > i32::MAX as i64 || left < -1 || right < -1 ||
            (left >= 0 && left as u64 >= count as u64) || (right >= 0 && right as u64 >= count as u64) { return -1; }
        if left >= 0 { parents[left as usize] += 1; if parents[left as usize] > 1 { return -1; } }
        if right >= 0 { parents[right as usize] += 1; if parents[right as usize] > 1 { return -1; } }
    }
    for i in 0..count { if parents[i] != (if i == root { 0 } else { 1 }) { return -1; } }
    let mut top = 1;
    let mut visited = 0;
    stack[0] = root;
    while top > 0 {
        top -= 1;
        let index = stack[top];
        if seen[index] { return -1; }
        seen[index] = true; visited += 1;
        let base = 2 + 3 * index;
        let left = *values.add(base + 1);
        let right = *values.add(base + 2);
        if left >= 0 { stack[top] = left as usize; top += 1; }
        if right >= 0 { stack[top] = right as usize; top += 1; }
    }
    if visited != count { return -1; }
    let mut required = 2 * (count - 1);
    for i in 0..count {
        let base = 2 + 3 * i;
        required += decimal_length(*values.add(base));
        if *values.add(base + 1) == -1 && *values.add(base + 2) >= 0 { required += 2; }
    }
    if output.is_null() || output_capacity < required { return -2; }
    let mut position = 0;
    emit_node(values, root, output, &mut position);
    position as i64
}
