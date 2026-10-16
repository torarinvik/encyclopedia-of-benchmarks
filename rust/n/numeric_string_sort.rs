/// Sort decimal strings by the pinned normalized-length/lexicographic comparator.
const MAX_ITEMS: usize = 64;
const MAX_TOKEN_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 2113;
const MAX_OUTPUT_LENGTH: usize = 2111;

#[derive(Clone, Copy)]
struct TokenRef {
    start: usize,
    length: usize,
    normalized_start: usize,
    normalized_length: usize,
}

unsafe fn token_less(values: *const i64, left: TokenRef, right: TokenRef) -> bool {
    if left.normalized_length != right.normalized_length {
        return left.normalized_length < right.normalized_length;
    }
    for i in 0..left.normalized_length {
        let a = *values.add(left.normalized_start + i);
        let b = *values.add(right.normalized_start + i);
        if a != b { return a < b; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn numeric_string_sort(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length == 0 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let raw_count = *values;
    if raw_count < 0 || raw_count > MAX_ITEMS as i64 { return -1; }
    let count = raw_count as usize;
    let mut tokens = [TokenRef { start: 0, length: 0, normalized_start: 0, normalized_length: 0 }; MAX_ITEMS];
    let mut order = [0usize; MAX_ITEMS];
    let mut cursor = 1usize;
    let mut output_length = if count == 0 { 0 } else { count - 1 };

    for item in 0..count {
        if cursor >= length { return -1; }
        let raw_length = *values.add(cursor);
        cursor += 1;
        if raw_length < 1 || raw_length > MAX_TOKEN_LENGTH as i64 { return -1; }
        let token_length = raw_length as usize;
        if token_length > length - cursor { return -1; }
        let start = cursor;
        for offset in 0..token_length {
            let byte = *values.add(start + offset);
            if !(b'0' as i64..=b'9' as i64).contains(&byte) { return -1; }
        }
        let mut zeros = 0usize;
        while zeros < token_length && *values.add(start + zeros) == b'0' as i64 { zeros += 1; }
        let current = TokenRef { start, length: token_length,
            normalized_start: start + zeros, normalized_length: token_length - zeros };
        tokens[item] = current;
        for previous in 0..item {
            let prior = tokens[previous];
            if prior.normalized_length != current.normalized_length { continue; }
            let mut equal = true;
            for offset in 0..current.normalized_length {
                if *values.add(prior.normalized_start + offset) != *values.add(current.normalized_start + offset) {
                    equal = false;
                    break;
                }
            }
            if equal {
                if prior.length != token_length { return -1; }
                for offset in 0..token_length {
                    if *values.add(prior.start + offset) != *values.add(start + offset) { return -1; }
                }
            }
        }
        output_length += token_length;
        cursor += token_length;
        order[item] = item;
    }
    if cursor != length || output_length > MAX_OUTPUT_LENGTH { return -1; }

    for item in 1..count {
        let key = order[item];
        let mut position = item;
        while position > 0 && token_less(values, tokens[key], tokens[order[position - 1]]) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = key;
    }
    if (output.is_null() && output_length != 0) || output_capacity < output_length { return -2; }
    let mut written = 0usize;
    for item in 0..count {
        if item > 0 { *output.add(written) = b' '; written += 1; }
        let token = tokens[order[item]];
        for offset in 0..token.length {
            *output.add(written) = *values.add(token.start + offset) as u8;
            written += 1;
        }
    }
    output_length as i64
}
