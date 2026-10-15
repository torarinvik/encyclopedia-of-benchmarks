const MAX_INPUT: usize = 2200;
const MAX_NODES: usize = 127;

fn ascii_space(value: i64) -> bool { value == b' ' as i64 || (b'\t' as i64..=b'\r' as i64).contains(&value) }

fn parse_integer(input: &[i64], mut first: usize, mut last: usize) -> Option<i32> {
    while first < last && ascii_space(input[first]) { first += 1; }
    while last > first && ascii_space(input[last - 1]) { last -= 1; }
    if first == last { return None; }
    let mut negative = false;
    if input[first] == b'-' as i64 || input[first] == b'+' as i64 {
        negative = input[first] == b'-' as i64;
        first += 1;
    }
    if first == last { return None; }
    let limit: i64 = if negative { 2_147_483_648 } else { 2_147_483_647 };
    let mut number = 0_i64;
    for &digit in &input[first..last] {
        if !(b'0' as i64..=b'9' as i64).contains(&digit) { return None; }
        let value = digit - b'0' as i64;
        if number > (limit - value) / 10 { return None; }
        number = number * 10 + value;
    }
    Some(if negative { -(number as i64) as i32 } else { number as i32 })
}

#[no_mangle]
pub unsafe extern "C" fn serialize_deserialize_binary_tree(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input.iter().any(|&value| !(0..=127).contains(&value)) { return -1; }
    let mut encoded = Vec::<u8>::with_capacity(length);
    let (mut position, mut slots, mut nodes) = (0_usize, 1_usize, 0_usize);
    while position < length {
        if slots == 0 { return -1; }
        let start = position;
        while position < length && input[position] != b',' as i64 { position += 1; }
        let end = position;
        if start == end { return -1; }
        let is_null = end - start == 4 && input[start..end] == [b'n' as i64, b'u' as i64, b'l' as i64, b'l' as i64];
        if !encoded.is_empty() { encoded.push(b','); }
        if is_null { encoded.extend_from_slice(b"null"); }
        else {
            let Some(number) = parse_integer(input, start, end) else { return -1; };
            nodes += 1;
            if nodes > MAX_NODES { return -1; }
            encoded.extend_from_slice(number.to_string().as_bytes());
        }
        slots -= 1;
        if !is_null { slots += 2; }
        if position < length { position += 1; if position == length { return -1; } }
    }
    if slots != 0 { return -1; }
    if output.is_null() || output_capacity < encoded.len() { return -2; }
    std::ptr::copy_nonoverlapping(encoded.as_ptr(), output, encoded.len());
    encoded.len() as i64
}
