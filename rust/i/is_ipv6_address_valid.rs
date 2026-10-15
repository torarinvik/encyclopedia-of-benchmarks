const MAX_INPUT_LENGTH: usize = 256;

fn is_hex_digit(value: i64) -> bool {
    (48..=57).contains(&value) || (97..=102).contains(&value) || (65..=70).contains(&value)
}

fn valid_ipv6_text(input: &[i64], text_length: usize) -> bool {
    if text_length == 0 { return false; }
    let mut groups = 0usize;
    let mut group_length = 0usize;
    let mut compression_count = 0usize;
    let mut in_group = false;
    let mut index = 0usize;
    while index < text_length {
        let value = input[index + 1];
        if value == 58 {
            if index + 1 < text_length && input[index + 2] == 58 {
                if (index > 0 && input[index] == 58)
                    || (index + 2 < text_length && input[index + 3] == 58)
                    || compression_count != 0 { return false; }
                if in_group {
                    groups += 1;
                    in_group = false;
                    group_length = 0;
                } else if index != 0 {
                    return false;
                }
                compression_count += 1;
                index += 2;
                continue;
            }
            if index == 0 || index + 1 == text_length || !in_group { return false; }
            groups += 1;
            in_group = false;
            group_length = 0;
            index += 1;
            continue;
        }
        if !is_hex_digit(value) || group_length == 4 { return false; }
        group_length += 1;
        in_group = true;
        index += 1;
    }
    if in_group { groups += 1; }
    if compression_count == 0 { groups == 8 } else { groups < 8 }
}

#[no_mangle]
pub unsafe extern "C" fn is_ipv6_address_valid(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length < 1 { return -1; }
    let input = std::slice::from_raw_parts(raw, length);
    if input[0] < 0 || input[0] > MAX_INPUT_LENGTH as i64 { return -1; }
    let text_length = input[0] as usize;
    if length != text_length + 1 || input[1..].iter().any(|value| *value < 0 || *value > 127) { return -1; }
    if valid_ipv6_text(input, text_length) { 1 } else { 0 }
}
