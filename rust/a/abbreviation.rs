/// Check whether lowercase source letters can be capitalized or deleted.
#[no_mangle]
pub extern "C" fn abbreviation(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > 258 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let (source_length, target_length) = (values[0], values[1]);
    if !(0..=128).contains(&source_length) || !(0..=128).contains(&target_length) {
        return -1;
    }
    let (source_length, target_length) = (source_length as usize, target_length as usize);
    if length != 2 + source_length + target_length {
        return -1;
    }
    let source = &values[2..2 + source_length];
    let target = &values[2 + source_length..];
    if source
        .iter()
        .any(|&value| !((b'A' as i64..=b'Z' as i64).contains(&value)
            || (b'a' as i64..=b'z' as i64).contains(&value)))
        || target
            .iter()
            .any(|&value| !(b'A' as i64..=b'Z' as i64).contains(&value))
    {
        return -1;
    }

    let mut current = [false; 129];
    let mut next = [false; 129];
    current[0] = true;
    for &value in source {
        next[..=target_length].fill(false);
        let uppercase = if (b'a' as i64..=b'z' as i64).contains(&value) {
            value - 32
        } else {
            value
        };
        for target_index in 0..=target_length {
            if !current[target_index] {
                continue;
            }
            if (b'a' as i64..=b'z' as i64).contains(&value) {
                next[target_index] = true;
            }
            if target_index < target_length && uppercase == target[target_index] {
                next[target_index + 1] = true;
            }
        }
        current[..=target_length].copy_from_slice(&next[..=target_length]);
    }
    i64::from(current[target_length])
}
