fn previous_bucket(index: isize) -> isize { (index & (index + 1)) - 1 }

#[no_mangle]
pub extern "C" fn maximum_fenwick_tree(input: *const i64, length: usize,
                                        output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 194 { return -1; }
    // The ABI supplies a valid readable slice whenever input is non-null.
    let words = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=64).contains(&words[0]) || !(0..=64).contains(&words[1]) { return -1; }
    let size = words[0] as usize;
    let op_count = words[1] as usize;
    if length != 2 + 3 * op_count { return -1; }
    let mut values = [0i32; 64];
    let mut tree = [0i32; 64];
    let mut results = [0i64; 64];
    let mut result_count = 0usize;
    for op in 0..op_count {
        let pos = 2 + 3 * op;
        let opcode = words[pos];
        let first = words[pos + 1];
        let second = words[pos + 2];
        if opcode == 0 {
            if first < 0 || first >= size as i64 || second < 0 || second > i32::MAX as i64 { return -1; }
            let mut index = first as usize;
            let old_value = values[index];
            let value = second as i32;
            values[index] = value;
            while index < size {
                let old_max = tree[index];
                if value > old_max { tree[index] = value; }
                else if old_value == old_max {
                    let left = (previous_bucket(index as isize) + 1) as usize;
                    let mut maximum = value;
                    let mut child = index as isize - 1;
                    while child >= left as isize {
                        maximum = maximum.max(tree[child as usize]);
                        if maximum == old_max { break; }
                        child = previous_bucket(child);
                    }
                    tree[index] = maximum;
                    if maximum == old_max { break; }
                } else { break; }
                index |= index + 1;
            }
        } else if opcode == 1 {
            if first < 0 || first > second || second > size as i64 { return -1; }
            let mut maximum = 0i32;
            let mut right = second - 1;
            while first <= right {
                let current_left = right & (right + 1);
                if first <= current_left {
                    maximum = maximum.max(tree[right as usize]);
                    right = current_left - 1;
                } else {
                    maximum = maximum.max(values[right as usize]);
                    right -= 1;
                }
            }
            results[result_count] = maximum as i64;
            result_count += 1;
        } else { return -1; }
    }
    let bytes = result_count * 8;
    if output.is_null() || output_capacity < bytes { return -2; }
    for i in 0..result_count {
        let bits = results[i] as u64;
        for b in 0..8 { unsafe { *output.add(8 * i + b) = (bits >> (8 * b)) as u8; } }
    }
    bytes as i64
}
