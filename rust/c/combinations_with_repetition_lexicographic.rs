fn multiset_count(n: usize, r: usize) -> usize {
    if r == 0 {
        return 1;
    }
    if n == 0 {
        return 0;
    }
    let top = n + r - 1;
    let mut result = 1usize;
    for index in 1..=r {
        result = result * (top - r + index) / index;
    }
    result
}

#[no_mangle]
pub unsafe extern "C" fn combinations_with_repetition_lexicographic(
    raw: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw.is_null() || length != 2 {
        return -1;
    }
    let input = std::slice::from_raw_parts(raw, length);
    if !(0..=4).contains(&input[0]) || !(0..=4).contains(&input[1]) {
        return -1;
    }
    let n = input[0] as usize;
    let r = input[1] as usize;
    let count = multiset_count(n, r);
    let byte_count = 2 + count * r;
    if output.is_null() || capacity < byte_count {
        return -2;
    }

    let destination = std::slice::from_raw_parts_mut(output, byte_count);
    destination[0] = (count & 255) as u8;
    destination[1] = ((count >> 8) & 255) as u8;
    let mut current = [0u8; 4];
    for ordinal in 0..count {
        for position in 0..r {
            destination[2 + ordinal * r + position] = current[position];
        }
        if ordinal + 1 == count || r == 0 {
            continue;
        }
        let mut position = r;
        while current[position - 1] == (n - 1) as u8 {
            position -= 1;
        }
        position -= 1;
        current[position] += 1;
        for suffix in (position + 1)..r {
            current[suffix] = current[position];
        }
    }
    byte_count as i64
}
