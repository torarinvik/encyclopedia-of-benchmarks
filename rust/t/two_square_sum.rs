const MAX_Q: usize = 8;
const MAX_N: i64 = 10_000;
const MAX_OUTPUT_BYTES: usize = 6_496;

fn integer_sqrt(value: i64) -> i64 {
    let (mut low, mut high) = (0_i64, value + 1);
    while high - low > 1 {
        let middle = low + (high - low) / 2;
        if middle * middle <= value {
            low = middle;
        } else {
            high = middle;
        }
    }
    low
}

unsafe fn write_u32(output: *mut u8, offset: usize, value: u32) {
    *output.add(offset) = value as u8;
    *output.add(offset + 1) = (value >> 8) as u8;
    *output.add(offset + 2) = (value >> 16) as u8;
    *output.add(offset + 3) = (value >> 24) as u8;
}

#[no_mangle]
pub unsafe extern "C" fn two_square_sum(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_Q + 1).contains(&length) {
        return -1;
    }
    let q64 = *input;
    if q64 < 1 || q64 > MAX_Q as i64 {
        return -1;
    }
    let q = q64 as usize;
    if length != q + 1 {
        return -1;
    }

    let mut numbers = [0_i64; MAX_Q];
    let mut counts = [0_usize; MAX_Q];
    let mut total_pairs = 0_usize;
    for query in 0..q {
        let n = *input.add(query + 1);
        if !(0..=MAX_N).contains(&n) {
            return -1;
        }
        numbers[query] = n;
        let mut a = 0_i64;
        while a * a <= n {
            let remainder = n - a * a;
            let b = integer_sqrt(remainder);
            if b * b == remainder {
                counts[query] += 1;
            }
            a += 1;
        }
        total_pairs += counts[query];
    }

    let required = 4 * (q + 2 * total_pairs);
    if output.is_null() || capacity < required || required > MAX_OUTPUT_BYTES {
        return -2;
    }
    let mut offset = 0_usize;
    for query in 0..q {
        write_u32(output, offset, counts[query] as u32);
        offset += 4;
        let n = numbers[query];
        let mut a = 0_i64;
        while a * a <= n {
            let remainder = n - a * a;
            let b = integer_sqrt(remainder);
            if b * b == remainder {
                write_u32(output, offset, a as u32);
                write_u32(output, offset + 4, b as u32);
                offset += 8;
            }
            a += 1;
        }
    }
    offset as i64
}
