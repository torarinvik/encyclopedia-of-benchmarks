const MAX_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 66;

fn sift(values: &mut [i64; MAX_COUNT], mut root: usize, mut order: usize, leonardo: &[usize; 16]) {
    while order > 1 {
        let right = root - 1;
        let left = root - 1 - leonardo[order - 2];
        if !(values[left] < values[right]) && values[root] < values[left] {
            values.swap(root, left); root = left; order -= 1;
        } else if values[left] < values[right] && values[root] < values[right] {
            values.swap(root, right); root = right; order -= 2;
        } else { break; }
    }
}
fn trinkle(values: &mut [i64; MAX_COUNT], mut position: usize,
           orders: &mut [usize; MAX_COUNT], mut index: usize, leonardo: &[usize; 16]) {
    while index > 0 {
        let previous = position - leonardo[orders[index]];
        if !(values[position] < values[previous]) { break; }
        if orders[index] > 1 {
            let right = position - 1;
            let left = position - 1 - leonardo[orders[index] - 2];
            if !(values[right] < values[previous]) || !(values[left] < values[previous]) { break; }
        }
        values.swap(position, previous); position = previous; index -= 1;
    }
    sift(values, position, orders[index], leonardo);
}
fn smooth_sort(values: &mut [i64; MAX_COUNT], count: usize) {
    if count < 2 { return; }
    let mut leonardo = [0usize; 16]; leonardo[0] = 1; leonardo[1] = 1;
    for i in 2..16 { leonardo[i] = leonardo[i - 1] + leonardo[i - 2] + 1; }
    let mut orders = [0usize; MAX_COUNT]; let mut heap_count = 0usize;
    for position in 0..count {
        if heap_count >= 2 && orders[heap_count - 2] == orders[heap_count - 1] + 1 {
            heap_count -= 1; orders[heap_count - 1] += 1;
        } else if heap_count > 0 && orders[heap_count - 1] == 1 { orders[heap_count] = 0; heap_count += 1; }
        else { orders[heap_count] = 1; heap_count += 1; }
        trinkle(values, position, &mut orders, heap_count - 1, &leonardo);
    }
    for position in (0..count).rev() {
        heap_count -= 1; let order = orders[heap_count];
        if order > 1 {
            let right_order = order - 2; let left_order = order - 1;
            let right_position = position - 1; let left_position = position - 1 - leonardo[right_order];
            orders[heap_count] = left_order; heap_count += 1;
            trinkle(values, left_position, &mut orders, heap_count - 1, &leonardo);
            orders[heap_count] = right_order; heap_count += 1;
            trinkle(values, right_position, &mut orders, heap_count - 1, &leonardo);
        }
    }
}
fn store_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn smoothsort(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let source = std::slice::from_raw_parts(input, length);
    if source[0] < 0 || source[0] > MAX_COUNT as i64 { return -1; }
    let count = source[0] as usize;
    if length != 1 + count || length > MAX_COUNT + 1 { return -1; }
    let mut values = [0i64; MAX_COUNT];
    values[..count].copy_from_slice(&source[1..]);
    smooth_sort(&mut values, count);
    let bytes = count * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..count { store_i64(output, i * 8, values[i]); }
    bytes as i64
}
