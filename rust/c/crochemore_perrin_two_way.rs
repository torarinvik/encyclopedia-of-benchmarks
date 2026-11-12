const MAX_TEXT_LENGTH: usize = 64;
const MAX_PATTERN_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 99;

fn maximal_suffix(pattern: &[i64], reverse_order: bool) -> (i32, i32) {
    let mut maximal = -1i32;
    let mut candidate = 0i32;
    let mut offset = 1i32;
    let mut period = 1i32;
    let length = pattern.len() as i32;
    while candidate + offset < length {
        let a = pattern[(candidate + offset) as usize];
        let b = pattern[(maximal + offset) as usize];
        let precedes = if reverse_order { a > b } else { a < b };
        if precedes {
            candidate += offset;
            offset = 1;
            period = candidate - maximal;
        } else if a == b {
            if offset != period {
                offset += 1;
            } else {
                candidate += period;
                offset = 1;
            }
        } else {
            maximal = candidate;
            candidate = maximal + 1;
            offset = 1;
            period = 1;
        }
    }
    (maximal, period)
}

fn two_way(text: &[i64], pattern: &[i64]) -> Vec<i64> {
    let n = text.len() as i32;
    let m = pattern.len() as i32;
    if m == 0 {
        return (0..=n).map(i64::from).collect();
    }
    if m > n {
        return Vec::new();
    }
    let first = maximal_suffix(pattern, false);
    let second = maximal_suffix(pattern, true);
    let (critical, period) = if first.0 > second.0 { first } else { second };
    let mut periodic = period + critical + 1 <= m;
    if periodic {
        for i in 0..=critical {
            if pattern[i as usize] != pattern[(i + period) as usize] {
                periodic = false;
                break;
            }
        }
    }
    let shift = if periodic { period } else { critical.max(m - critical - 1) + 1 };
    let mut memory = -1i32;
    let mut start = 0i32;
    let mut matches = Vec::new();
    while start <= n - m {
        let mut index = if periodic { critical.max(memory) + 1 } else { critical + 1 };
        while index < m
            && pattern[index as usize] == text[(start + index) as usize]
        {
            index += 1;
        }
        if index >= m {
            index = critical;
            while index > memory
                && pattern[index as usize] == text[(start + index) as usize]
            {
                index -= 1;
            }
            if index <= memory {
                matches.push(i64::from(start));
            }
            start += shift;
            memory = if periodic { m - period - 1 } else { -1 };
        } else {
            start += index - critical;
            memory = -1;
        }
    }
    matches
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8);
}

#[no_mangle]
pub unsafe extern "C" fn crochemore_perrin_two_way(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > MAX_TEXT_LENGTH as i64
        || input[1] < 0 || input[1] > MAX_PATTERN_LENGTH as i64
    {
        return -1;
    }
    let text_length = input[0] as usize;
    let pattern_length = input[1] as usize;
    if length != 2 + text_length + pattern_length {
        return -1;
    }
    let text = &input[2..2 + text_length];
    let pattern = &input[2 + text_length..];
    if text.iter().chain(pattern).any(|&value| !(0..=255).contains(&value)) {
        return -1;
    }
    let matches = two_way(text, pattern);
    let output_bytes = matches.len() * 8;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    for (i, &position) in matches.iter().enumerate() {
        store_i64_le(output, i * 8, position);
    }
    output_bytes as i64
}
