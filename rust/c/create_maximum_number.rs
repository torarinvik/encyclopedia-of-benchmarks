const MAX_SOURCE_LENGTH: usize = 6;
const MAX_INPUT_LENGTH: usize = 16;
const MAX_OUTPUT_LENGTH: usize = 12;

#[derive(Clone, Copy)]
struct Sequence {
    values: [u8; MAX_OUTPUT_LENGTH],
    length: usize,
}

impl Sequence {
    const fn empty() -> Self {
        Self { values: [0; MAX_OUTPUT_LENGTH], length: 0 }
    }
}

fn maximum_subsequence(source: &[i64], requested: usize) -> Sequence {
    let mut stack = [0_u8; MAX_SOURCE_LENGTH];
    let mut stack_length = 0;
    let mut deletions = source.len() - requested;
    for &value in source {
        let digit = value as u8;
        while deletions > 0 && stack_length > 0 && stack[stack_length - 1] < digit {
            stack_length -= 1;
            deletions -= 1;
        }
        stack[stack_length] = digit;
        stack_length += 1;
    }
    stack_length -= deletions;
    let mut selected = Sequence::empty();
    selected.length = stack_length;
    selected.values[..stack_length].copy_from_slice(&stack[..stack_length]);
    selected
}

fn compare_suffix(first: &Sequence, i: usize, second: &Sequence, j: usize) -> i8 {
    let mut a = i;
    let mut b = j;
    while a < first.length && b < second.length {
        if first.values[a] != second.values[b] {
            return if first.values[a] > second.values[b] { 1 } else { -1 };
        }
        a += 1;
        b += 1;
    }
    if a == first.length && b == second.length { 0 }
    else if a == first.length { -1 }
    else { 1 }
}

fn merge_sequences(first: &Sequence, second: &Sequence) -> Sequence {
    let mut merged = Sequence::empty();
    let (mut i, mut j) = (0, 0);
    while i < first.length || j < second.length {
        let order = compare_suffix(first, i, second, j);
        if j == second.length || (i < first.length && order >= 0) {
            merged.values[merged.length] = first.values[i];
            i += 1;
        } else {
            merged.values[merged.length] = second.values[j];
            j += 1;
        }
        merged.length += 1;
    }
    merged
}

fn greater(left: &Sequence, right: &Sequence) -> bool {
    for i in 0..left.length {
        if left.values[i] != right.values[i] { return left.values[i] > right.values[i]; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn create_maximum_number(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_SOURCE_LENGTH as i64
        || values[1] < 0 || values[1] > MAX_SOURCE_LENGTH as i64 { return -1; }
    let first_length = values[0] as usize;
    let second_length = values[1] as usize;
    if values[2] < 0 || values[2] > (first_length + second_length) as i64 { return -1; }
    let requested = values[2] as usize;
    if length != 3 + first_length + second_length { return -1; }
    if values[3..].iter().any(|&digit| !(0..=9).contains(&digit)) { return -1; }
    if output.is_null() || capacity < requested { return -2; }

    let first = &values[3..3 + first_length];
    let second = &values[3 + first_length..];
    let minimum_first = requested.saturating_sub(second_length);
    let maximum_first = requested.min(first_length);
    let mut best = Sequence::empty();
    let mut have_best = false;
    for take_first in minimum_first..=maximum_first {
        let selected_first = maximum_subsequence(first, take_first);
        let selected_second = maximum_subsequence(second, requested - take_first);
        let candidate = merge_sequences(&selected_first, &selected_second);
        if !have_best || greater(&candidate, &best) {
            best = candidate;
            have_best = true;
        }
    }
    for i in 0..requested { *output.add(i) = best.values[i]; }
    requested as i64
}
