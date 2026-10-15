/// Track unmatched opening positions to find the longest valid parentheses substring.
const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn longest_valid_parentheses_stack(input: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    let values = if length == 0 { &[][..] } else { unsafe { std::slice::from_raw_parts(input, length) } };
    if values.iter().any(|&value| value != 40 && value != 41) { return -1; }

    let mut unmatched = [0isize; MAX_LENGTH + 1];
    let mut top = 0usize;
    unmatched[top] = -1;
    let mut best = 0usize;
    for (index, &value) in values.iter().enumerate() {
        if value == 40 {
            top += 1;
            unmatched[top] = index as isize;
        } else if top == 0 {
            unmatched[0] = index as isize;
        } else {
            top -= 1;
            let current = index as isize - unmatched[top];
            best = best.max(current as usize);
        }
    }
    best as i64
}
