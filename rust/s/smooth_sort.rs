const MAX_N: usize = 512;
const MAX_VALID_INPUT_LENGTH: usize = 513;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 514;
const MAX_VALUE: i64 = 1_000_000;
const OFFSET: i64 = 1_000_001;
const LEONARDO: [usize; 16] = [1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973];

fn less(left: i64, right: i64) -> bool { left < right }

fn sift(values: &mut [i64; MAX_N], mut order: usize, mut root: usize) {
    let value = values[root];
    while order > 1 {
        let right = root - 1;
        let left = root - 1 - LEONARDO[order - 2];
        if !less(value, values[left]) && !less(value, values[right]) { break; }
        if !less(values[left], values[right]) {
            values[root] = values[left];
            root = left;
            order -= 1;
        } else {
            values[root] = values[right];
            root = right;
            order -= 2;
        }
    }
    values[root] = value;
}

fn trinkle(values: &mut [i64; MAX_N], mut p: u64, mut order: usize, mut root: usize, mut trusty: bool) {
    let value = values[root];
    while p != 1 {
        let stepson = root - LEONARDO[order];
        if !less(value, values[stepson]) { break; }
        if !trusty && order > 1 {
            let right = root - 1;
            let left = root - 1 - LEONARDO[order - 2];
            if !less(values[right], values[stepson]) || !less(values[left], values[stepson]) { break; }
        }
        values[root] = values[stepson];
        root = stepson;
        let mask = p & !1_u64;
        let shift = mask.trailing_zeros() as usize;
        p >>= shift;
        order += shift;
        trusty = false;
    }
    if !trusty {
        values[root] = value;
        sift(values, order, root);
    }
}

fn smoothsort(values: &mut [i64; MAX_N], length: usize) {
    if length < 2 { return; }
    let last = length - 1;
    let mut p = 1_u64;
    let mut pshift = 1_usize;
    let mut head = 0_usize;
    while head < last {
        if (p & 3) == 3 {
            sift(values, pshift, head);
            p >>= 2;
            pshift += 2;
        } else {
            if LEONARDO[pshift - 1] >= last - head { trinkle(values, p, pshift, head, false); }
            else { sift(values, pshift, head); }
            if pshift == 1 {
                p <<= 1;
                pshift = 0;
            } else {
                p <<= pshift - 1;
                pshift = 1;
            }
        }
        p |= 1;
        head += 1;
    }
    trinkle(values, p, pshift, head, false);
    while pshift != 1 || p != 1 {
        if pshift <= 1 {
            let mask = p & !1_u64;
            let shift = mask.trailing_zeros() as usize;
            p >>= shift;
            pshift += shift;
        } else {
            p <<= 2;
            p ^= 7;
            pshift -= 2;
            trinkle(values, p >> 1, pshift + 1, head - LEONARDO[pshift] - 1, true);
            trinkle(values, p, pshift, head - 1, true);
        }
        head -= 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn smooth_sort_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH || length > MAX_VALID_INPUT_LENGTH { return -1; }
    let input_values = std::slice::from_raw_parts(input, length);
    if input_values[0] < 0 || input_values[0] > MAX_N as i64 { return -1; }
    let count = input_values[0] as usize;
    if length != count + 1 { return -1; }
    let mut values = [0_i64; MAX_N];
    for index in 0..count {
        let value = input_values[index + 1];
        if !(-MAX_VALUE..=MAX_VALUE).contains(&value) { return -1; }
        values[index] = value;
    }
    smoothsort(&mut values, count);
    let mut checksum = 0_i64;
    for index in 0..count { checksum += (index as i64 + 1) * (values[index] + OFFSET); }
    checksum
}
