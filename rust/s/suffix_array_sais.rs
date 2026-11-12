const MAX_TEXT_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;
const MAX_ALPHABET: usize = 256;

fn induce(
    symbols: &[i32],
    is_s: &[bool],
    sum_s: &[usize; MAX_ALPHABET + 2],
    sum_l: &[usize; MAX_ALPHABET + 2],
    ordered_lms: &[usize],
) -> Vec<usize> {
    let n = symbols.len();
    let mut suffixes = vec![usize::MAX; n];
    let mut bucket = *sum_s;
    for &position in ordered_lms {
        suffixes[bucket[symbols[position] as usize]] = position;
        bucket[symbols[position] as usize] += 1;
    }
    bucket = *sum_l;
    for slot in 0..n {
        let position = suffixes[slot];
        if position != usize::MAX && position > 0 && !is_s[position - 1] {
            let symbol = symbols[position - 1] as usize;
            suffixes[bucket[symbol]] = position - 1;
            bucket[symbol] += 1;
        }
    }
    bucket = *sum_l;
    for slot in (0..n).rev() {
        let position = suffixes[slot];
        if position != usize::MAX && position > 0 && is_s[position - 1] {
            let symbol = symbols[position - 1] as usize + 1;
            bucket[symbol] -= 1;
            suffixes[bucket[symbol]] = position - 1;
        }
    }
    suffixes
}

fn same_lms_substring(
    symbols: &[i32],
    is_s: &[bool],
    lms_map: &[isize],
    left: usize,
    right: usize,
) -> bool {
    if left == right {
        return true;
    }
    for offset in 0..symbols.len() {
        let a = left + offset;
        let b = right + offset;
        if a >= symbols.len() || b >= symbols.len() || symbols[a] != symbols[b] || is_s[a] != is_s[b] {
            return false;
        }
        let a_lms = offset > 0 && lms_map[a] >= 0;
        let b_lms = offset > 0 && lms_map[b] >= 0;
        if a_lms || b_lms {
            return a_lms && b_lms;
        }
    }
    false
}

fn sais(symbols: &[i32], upper: usize) -> Vec<usize> {
    let n = symbols.len();
    if n == 0 {
        return Vec::new();
    }
    if n <= 2 {
        let mut suffixes: Vec<usize> = (0..n).collect();
        if n == 2 && symbols[0] >= symbols[1] {
            suffixes.swap(0, 1);
        }
        return suffixes;
    }

    let mut is_s = vec![false; n];
    is_s[n - 1] = true;
    for i in (0..n - 1).rev() {
        is_s[i] = symbols[i] < symbols[i + 1]
            || (symbols[i] == symbols[i + 1] && is_s[i + 1]);
    }
    let mut lms_map = vec![-1isize; n + 1];
    let mut lms = Vec::new();
    for i in 1..n {
        if !is_s[i - 1] && is_s[i] {
            lms_map[i] = lms.len() as isize;
            lms.push(i);
        }
    }

    let mut sum_s = [0usize; MAX_ALPHABET + 2];
    let mut sum_l = [0usize; MAX_ALPHABET + 2];
    for i in 0..n {
        let symbol = symbols[i] as usize;
        if is_s[i] {
            sum_l[symbol + 1] += 1;
        } else {
            sum_s[symbol] += 1;
        }
    }
    for symbol in 0..=upper {
        sum_s[symbol] += sum_l[symbol];
        sum_l[symbol + 1] += sum_s[symbol];
    }

    let suffixes = induce(symbols, &is_s, &sum_s, &sum_l, &lms);
    let sorted_lms: Vec<usize> = suffixes
        .iter()
        .copied()
        .filter(|&position| position != usize::MAX && lms_map[position] >= 0)
        .collect();
    let mut reduced = vec![0i32; lms.len()];
    let mut reduced_upper = 0usize;
    for i in 0..sorted_lms.len() {
        if i > 0 && !same_lms_substring(symbols, &is_s, &lms_map, sorted_lms[i - 1], sorted_lms[i]) {
            reduced_upper += 1;
        }
        reduced[lms_map[sorted_lms[i]] as usize] = reduced_upper as i32;
    }

    let reduced_order = if reduced_upper + 1 == reduced.len() {
        let mut order = vec![0usize; reduced.len()];
        for (index, &name) in reduced.iter().enumerate() {
            order[name as usize] = index;
        }
        order
    } else {
        sais(&reduced, reduced_upper)
    };
    let ordered_lms: Vec<usize> = reduced_order.iter().map(|&index| lms[index]).collect();
    induce(symbols, &is_s, &sum_s, &sum_l, &ordered_lms)
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8);
}

#[no_mangle]
pub unsafe extern "C" fn suffix_array_sais(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] > MAX_TEXT_LENGTH as i64 {
        return -1;
    }
    let count = input[0] as usize;
    if length != count + 1 || input[1..].iter().any(|&value| !(0..=255).contains(&value)) {
        return -1;
    }
    let output_bytes = count * 8;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let mut symbols: Vec<i32> = input[1..].iter().map(|&value| value as i32 + 1).collect();
    symbols.push(0);
    let suffixes = sais(&symbols, 256);
    let mut out = 0usize;
    for position in suffixes {
        if position == count {
            continue;
        }
        store_i64_le(output, out * 8, position as i64);
        out += 1;
    }
    output_bytes as i64
}
