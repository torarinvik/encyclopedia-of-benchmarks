#[no_mangle]
pub extern "C" fn duplicate_brackets(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length < 1 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(packed, length) };
    let count = values[0];
    if !(0..=256).contains(&count) || length != count as usize + 1 {
        return -1;
    }
    let bytes = &values[1..];
    let mut depth = 0i64;
    for &ch in bytes {
        if !(32..=126).contains(&ch) {
            return -1;
        }
        if ch == 40 {
            depth += 1;
        } else if ch == 41 {
            depth -= 1;
            if depth < 0 {
                return -1;
            }
        }
    }
    if depth != 0 {
        return -1;
    }
    let mut stack = [0i64; 256];
    let mut top = 0usize;
    for &ch in bytes {
        if ch == 41 {
            if top == 0 || stack[top - 1] == 40 {
                return 1;
            }
            while top > 0 && stack[top - 1] != 40 {
                top -= 1;
            }
            if top > 0 {
                top -= 1;
            }
        } else {
            stack[top] = ch;
            top += 1;
        }
    }
    0
}
