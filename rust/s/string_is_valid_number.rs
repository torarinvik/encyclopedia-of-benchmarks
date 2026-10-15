#[no_mangle]
pub unsafe extern "C" fn string_is_valid_number(bytes: *const i64, length: usize) -> i64 {
    if length > 256 || (length != 0 && bytes.is_null()) {
        return -1;
    }
    let bytes = if length == 0 {
        &[][..]
    } else {
        std::slice::from_raw_parts(bytes, length)
    };
    if bytes.iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let mut state = 0;
    for &ch in bytes {
        if (48..=57).contains(&ch) {
            if state == 0 || state == 1 { state = 2; }
            else if state == 3 { state = 4; }
            else if state == 5 || state == 6 { state = 7; }
            else if state != 2 && state != 4 && state != 7 { return 0; }
        } else if ch == 43 || ch == 45 {
            if state == 0 { state = 1; }
            else if state == 5 { state = 6; }
            else { return 0; }
        } else if ch == 46 {
            if state == 0 || state == 1 { state = 3; }
            else if state == 2 { state = 4; }
            else { return 0; }
        } else if ch == 101 || ch == 69 {
            if state == 2 || state == 4 { state = 5; }
            else { return 0; }
        } else {
            return 0;
        }
    }
    if state == 2 || state == 4 || state == 7 { 1 } else { 0 }
}
