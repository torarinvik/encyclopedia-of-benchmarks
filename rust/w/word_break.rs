/// Bottom-up word segmentation over packed lowercase ASCII letter codes.
#[no_mangle]
pub extern "C" fn word_break(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > 1122 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let text_length_value = values[0];
    let word_count_value = values[1];
    if !(0..=64).contains(&text_length_value) || !(0..=32).contains(&word_count_value) {
        return -1;
    }
    let text_length = text_length_value as usize;
    let word_count = word_count_value as usize;
    let dictionary_start = 2 + text_length;
    if length != dictionary_start + word_count * 33 {
        return -1;
    }
    if values[2..dictionary_start].iter().any(|code| !(1..=26).contains(code)) {
        return -1;
    }
    for word in 0..word_count {
        let slot = dictionary_start + word * 33;
        let word_length = values[slot];
        if !(1..=32).contains(&word_length) {
            return -1;
        }
        for index in 0..32 {
            let code = values[slot + 1 + index];
            if index < word_length as usize {
                if !(1..=26).contains(&code) {
                    return -1;
                }
            } else if code != 0 {
                return -1;
            }
        }
    }

    let mut reachable = [false; 65];
    reachable[0] = true;
    for start in 0..text_length {
        if !reachable[start] {
            continue;
        }
        for word in 0..word_count {
            let slot = dictionary_start + word * 33;
            let word_length = values[slot] as usize;
            if word_length > text_length - start {
                continue;
            }
            if values[2 + start..2 + start + word_length]
                == values[slot + 1..slot + 1 + word_length]
            {
                reachable[start + word_length] = true;
            }
        }
    }
    reachable[text_length] as i64
}
