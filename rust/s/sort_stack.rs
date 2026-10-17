const MAX_ITEMS: usize = 64;

fn insert_sorted(stack: &mut [i32; MAX_ITEMS], size: &mut usize, value: i32) {
    if *size == 0 || value > stack[*size - 1] {
        stack[*size] = value;
        *size += 1;
        return;
    }
    *size -= 1;
    let top = stack[*size];
    insert_sorted(stack, size, value);
    stack[*size] = top;
    *size += 1;
}

fn sort_recursively(stack: &mut [i32; MAX_ITEMS], size: &mut usize) {
    if *size == 0 { return; }
    *size -= 1;
    let top = stack[*size];
    sort_recursively(stack, size);
    insert_sorted(stack, size, top);
}

#[no_mangle]
pub unsafe extern "C" fn sort_stack(input: *const i64, length: usize,
        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 65 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_ITEMS as i64 || length != 1 + values[0] as usize { return -1; }
    let count = values[0] as usize;
    let mut stack = [0i32; MAX_ITEMS];
    for i in 0..count {
        if values[i + 1] < i32::MIN as i64 || values[i + 1] > i32::MAX as i64 { return -1; }
        stack[i] = values[i + 1] as i32;
    }
    let mut size = count;
    sort_recursively(&mut stack, &mut size);
    let bytes = size * 4;
    if output.is_null() || output_capacity < bytes { return -2; }
    for i in 0..size {
        let encoded = stack[i].to_le_bytes();
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(i * 4), 4);
    }
    bytes as i64
}
