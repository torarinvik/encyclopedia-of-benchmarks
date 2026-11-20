const MAX_OPERATIONS: usize = 24;
const RECORD_WIDTH: usize = 3;
const MAX_INPUT_VALUES: usize = 73;
const MAX_INTERVALS: usize = 25;
const DOMAIN_END: i64 = 32;

#[derive(Clone, Copy, Default)]
struct Interval {
    left: i64,
    right: i64,
}

fn add_interval(items: &mut [Interval; MAX_INTERVALS], count: &mut usize,
                mut left: i64, mut right: i64) {
    if left == right { return; }
    let mut next = [Interval::default(); MAX_INTERVALS];
    let mut out = 0;
    let mut inserted = false;
    for current in items[..*count].iter().copied() {
        if current.right < left {
            next[out] = current;
            out += 1;
        } else if right < current.left {
            if !inserted {
                next[out] = Interval { left, right };
                out += 1;
                inserted = true;
            }
            next[out] = current;
            out += 1;
        } else {
            left = left.min(current.left);
            right = right.max(current.right);
        }
    }
    if !inserted {
        next[out] = Interval { left, right };
        out += 1;
    }
    items[..out].copy_from_slice(&next[..out]);
    *count = out;
}

fn remove_interval(items: &mut [Interval; MAX_INTERVALS], count: &mut usize,
                   left: i64, right: i64) {
    if left == right { return; }
    let mut next = [Interval::default(); MAX_INTERVALS + 1];
    let mut out = 0;
    for current in items[..*count].iter().copied() {
        if current.right <= left || current.left >= right {
            next[out] = current;
            out += 1;
        } else {
            if current.left < left {
                next[out] = Interval { left: current.left, right: left };
                out += 1;
            }
            if current.right > right {
                next[out] = Interval { left: right, right: current.right };
                out += 1;
            }
        }
    }
    items[..out].copy_from_slice(&next[..out]);
    *count = out;
}

fn covered_length(items: &[Interval; MAX_INTERVALS], count: usize) -> i64 {
    items[..count].iter().map(|item| item.right - item.left).sum()
}

fn valid_input(values: &[i64]) -> Option<usize> {
    if values.is_empty() || values.len() > MAX_INPUT_VALUES { return None; }
    if values[0] < 0 || values[0] > MAX_OPERATIONS as i64 { return None; }
    let count = values[0] as usize;
    if values.len() != 1 + count * RECORD_WIDTH { return None; }
    for row in 0..count {
        let offset = 1 + row * RECORD_WIDTH;
        let opcode = values[offset];
        let left = values[offset + 1];
        let right = values[offset + 2];
        if !(0..=1).contains(&opcode) || left < 0 || right < left || right > DOMAIN_END {
            return None;
        }
    }
    Some(count)
}

#[no_mangle]
pub unsafe extern "C" fn interval_container(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_INPUT_VALUES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let operation_count = match valid_input(values) {
        Some(count) => count,
        None => return -1,
    };
    let mut items = [Interval::default(); MAX_INTERVALS];
    let mut count = 0;
    let mut checksum = 0_i64;
    for index in 0..operation_count {
        let offset = 1 + index * RECORD_WIDTH;
        let opcode = values[offset];
        let left = values[offset + 1];
        let right = values[offset + 2];
        if opcode == 0 { add_interval(&mut items, &mut count, left, right); }
        else { remove_interval(&mut items, &mut count, left, right); }
        checksum += (index as i64 + 1) * covered_length(&items, count);
    }
    checksum
}
