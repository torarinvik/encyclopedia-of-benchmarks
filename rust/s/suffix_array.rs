const MAX_TEXT_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 65;

fn pair_less(left: usize, right: usize, rank: &[i64; MAX_TEXT_LENGTH],
             length: usize, step: usize) -> bool {
    if rank[left] != rank[right] { return rank[left] < rank[right]; }
    let left_second = if left + step < length { rank[left + step] } else { -1 };
    let right_second = if right + step < length { rank[right + step] } else { -1 };
    left_second < right_second
}

#[no_mangle]
pub unsafe extern "C" fn suffix_array(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let count_value = input[0];
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&count_value) { return -1; }
    let count = count_value as usize;
    if length != 1 + count { return -1; }
    if input[1..].iter().any(|&value| !(0..=127).contains(&value)) { return -1; }

    let output_bytes = count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    if count == 0 { return 0; }

    let mut suffixes = [0usize; MAX_TEXT_LENGTH];
    let mut rank = [0i64; MAX_TEXT_LENGTH];
    let mut next_rank = [0i64; MAX_TEXT_LENGTH];
    for i in 0..count {
        suffixes[i] = i;
        rank[i] = input[1 + i];
    }

    let mut step = 1;
    while step < count {
        for i in 1..count {
            let key = suffixes[i];
            let mut position = i;
            while position > 0 && pair_less(key, suffixes[position - 1], &rank, count, step) {
                suffixes[position] = suffixes[position - 1];
                position -= 1;
            }
            suffixes[position] = key;
        }
        next_rank[suffixes[0]] = 0;
        for i in 1..count {
            let previous = suffixes[i - 1];
            let current = suffixes[i];
            let previous_second = if previous + step < count { rank[previous + step] } else { -1 };
            let current_second = if current + step < count { rank[current + step] } else { -1 };
            next_rank[current] = next_rank[previous] +
                if rank[previous] == rank[current] && previous_second == current_second { 0 } else { 1 };
        }
        for i in 0..count { rank[i] = next_rank[i]; }
        if rank[suffixes[count - 1]] == (count - 1) as i64 { break; }
        step *= 2;
    }

    for i in 0..count {
        let encoded = (suffixes[i] as i64).to_le_bytes();
        std::ptr::copy_nonoverlapping(encoded.as_ptr(), output.add(i * 8), 8);
    }
    output_bytes as i64
}
