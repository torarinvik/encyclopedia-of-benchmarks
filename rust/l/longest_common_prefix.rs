use std::cmp::Ordering;

fn compare_strings(input: &[i64], start_a: usize, len_a: usize, start_b: usize, len_b: usize) -> Ordering {
    let common = len_a.min(len_b);
    for i in 0..common {
        match input[start_a + i].cmp(&input[start_b + i]) {
            Ordering::Equal => {}
            other => return other,
        }
    }
    len_a.cmp(&len_b)
}

#[no_mangle]
pub unsafe extern "C" fn longest_common_prefix(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || length == 0 || length > 1041 { return -1; }
    let input = std::slice::from_raw_parts(raw, length);
    if !(0..=16).contains(&input[0]) { return -1; }
    let count = input[0] as usize;
    let mut starts = [0usize; 16];
    let mut sizes = [0usize; 16];
    let mut position = 1usize;
    for i in 0..count {
        if position >= length || !(0..=64).contains(&input[position]) { return -1; }
        sizes[i] = input[position] as usize;
        position += 1;
        if sizes[i] > length - position { return -1; }
        starts[i] = position;
        if input[position..position + sizes[i]].iter().any(|&b| !(0..=127).contains(&b)) { return -1; }
        position += sizes[i];
    }
    if position != length { return -1; }
    if count == 0 { return 0; }
    let mut order = [0usize; 16];
    for i in 0..count { order[i] = i; }
    for i in 1..count {
        let value = order[i];
        let mut j = i;
        while j > 0 && compare_strings(input, starts[order[j - 1]], sizes[order[j - 1]], starts[value], sizes[value]) == Ordering::Greater {
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = value;
    }
    let first = order[0]; let last = order[count - 1];
    let limit = sizes[first].min(sizes[last]);
    let mut prefix = 0usize;
    while prefix < limit && input[starts[first] + prefix] == input[starts[last] + prefix] { prefix += 1; }
    if capacity < prefix || (prefix > 0 && output.is_null()) { return -2; }
    for i in 0..prefix { *output.add(i) = input[starts[first] + i] as u8; }
    prefix as i64
}
