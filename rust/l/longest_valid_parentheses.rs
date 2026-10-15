/// Memoized endpoint recurrence, evaluated bottom-up from right to left.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn longest_valid_parentheses(input: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    let values = if length == 0 { &[][..] } else { unsafe { std::slice::from_raw_parts(input, length) } };
    if values.iter().any(|&value| value != 40 && value != 41) { return -1; }

    let mut end_exclusive = [0usize; MAX_LENGTH];
    let mut best = 0usize;
    for remaining in (1..=length).rev() {
        let index = remaining - 1;
        if values[index] == 40 {
            if index + 1 < length && values[index + 1] == 41 {
                end_exclusive[index] = index + 2;
                if index + 2 < length {
                    end_exclusive[index] = end_exclusive[index].max(end_exclusive[index + 2]);
                }
            } else if index + 1 < length {
                let nested_end = end_exclusive[index + 1];
                if nested_end > 0 && nested_end < length && values[nested_end] == 41 {
                    end_exclusive[index] = nested_end + 1;
                    if nested_end + 1 < length {
                        end_exclusive[index] = end_exclusive[index].max(end_exclusive[nested_end + 1]);
                    }
                }
            }
        }
        if end_exclusive[index] > index {
            best = best.max(end_exclusive[index] - index);
        }
    }
    best as i64
}
