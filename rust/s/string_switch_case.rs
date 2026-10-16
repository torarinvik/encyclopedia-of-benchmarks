const MAX_TEXT_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 3;

fn is_space(value: i64) -> bool {
    value == 32 || (9..=13).contains(&value) || (28..=31).contains(&value)
}
fn is_word(value: i64) -> bool {
    (65..=90).contains(&value) || (97..=122).contains(&value) || (48..=57).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn string_switch_case(input: *const i64, length: usize,
                                              output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let mode = *input;
    let separator = *input.add(1);
    let text_length = *input.add(2);
    if !(0..=8).contains(&mode) || !(0..=127).contains(&separator) ||
        !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length) ||
        length != text_length as usize + 3 || ((mode != 3 && mode != 4) && separator != 0) {
        return -1;
    }
    for i in 0..text_length as usize {
        let value = *input.add(i + 3);
        if !(0..=127).contains(&value) { return -1; }
    }

    let mut result = [0u8; MAX_TEXT_LENGTH];
    let mut used = 0usize;
    if mode <= 2 {
        let mut at_word_start = true;
        for i in 0..text_length as usize {
            let mut value = *input.add(i + 3);
            if !is_word(value) { at_word_start = true; continue; }
            if at_word_start {
                if (97..=122).contains(&value) { value -= 32; }
                at_word_start = false;
            } else if (65..=90).contains(&value) { value += 32; }
            result[used] = value as u8;
            used += 1;
        }
        if mode == 2 {
            if used == 0 {
                for value in b"not valid string" { result[used] = *value; used += 1; }
            } else if (65..=90).contains(&result[0]) { result[0] += 32; }
        }
    } else {
        let upper = mode == 4 || mode == 6 || mode == 8;
        let delimiter = if mode <= 4 { separator as u8 } else if mode <= 6 { b'_' } else { b'-' };
        let mut group_has_word = false;
        let mut pending_space = false;
        for i in 0..text_length as usize {
            let mut value = *input.add(i + 3);
            if is_space(value) { if group_has_word { pending_space = true; } continue; }
            if !is_word(value) { group_has_word = false; pending_space = false; continue; }
            if pending_space && group_has_word { result[used] = delimiter; used += 1; }
            pending_space = false;
            if upper && (97..=122).contains(&value) { value -= 32; }
            else if !upper && (65..=90).contains(&value) { value += 32; }
            result[used] = value as u8;
            used += 1;
            group_has_word = true;
        }
    }
    if used > capacity || (used > 0 && output.is_null()) { return -2; }
    if used > 0 { std::ptr::copy_nonoverlapping(result.as_ptr(), output, used); }
    used as i64
}
