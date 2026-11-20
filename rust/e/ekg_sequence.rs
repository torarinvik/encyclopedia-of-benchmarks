const MAX_N: i64 = 8;
const MAX_CANDIDATE: usize = 40_320;
const MAX_PARSEABLE_LENGTH: usize = 2;

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

#[no_mangle]
pub unsafe extern "C" fn ekg_sequence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    let requested = *input;
    if length != 1 || !(1..=MAX_N).contains(&requested) {
        return -1;
    }

    let mut terms = [0i64; MAX_N as usize];
    let mut used = [0u8; MAX_CANDIDATE + 1];
    terms[0] = 1;
    used[1] = 1;
    let mut term_count = 1usize;
    if requested >= 2 {
        terms[1] = 2;
        used[2] = 1;
        term_count = 2;
    }

    while term_count < requested as usize {
        let position = (term_count + 1) as i64;
        let previous = terms[term_count - 1];
        let search_bound = previous * position;
        let mut candidate = 1i64;
        while candidate <= search_bound {
            if used[candidate as usize] == 0 && gcd_i64(previous, candidate) > 1 {
                break;
            }
            candidate += 1;
        }
        if candidate > search_bound {
            return -1;
        }
        terms[term_count] = candidate;
        used[candidate as usize] = 1;
        term_count += 1;
    }

    let output_bytes = requested as usize * 8;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for index in 0..term_count {
        output_slice[index * 8..index * 8 + 8].copy_from_slice(&terms[index].to_le_bytes());
    }
    output_bytes as i64
}
