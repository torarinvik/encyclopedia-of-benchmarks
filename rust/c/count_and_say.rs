/// Generate the nth count-and-say term as ASCII bytes.
const MAX_TERM_LENGTH: usize = 256;

#[no_mangle]
pub unsafe extern "C" fn count_and_say(term_index: i64, output: *mut u8,
    output_capacity: usize) -> i64 {
    if !(1..=19).contains(&term_index) { return -1; }
    let mut current = [0u8; MAX_TERM_LENGTH];
    let mut next = [0u8; MAX_TERM_LENGTH];
    let mut current_length = 1;
    current[0] = b'1';
    for _ in 1..term_index {
        let mut next_length = 0;
        let mut index = 0;
        while index < current_length {
            let mut end = index + 1;
            while end < current_length && current[end] == current[index] { end += 1; }
            let run_length = end - index;
            if next_length + 2 > MAX_TERM_LENGTH { return -1; }
            next[next_length] = b'0' + run_length as u8;
            next[next_length + 1] = current[index];
            next_length += 2;
            index = end;
        }
        current[..next_length].copy_from_slice(&next[..next_length]);
        current_length = next_length;
    }
    if output_capacity < current_length || output.is_null() { return -2; }
    for index in 0..current_length { *output.add(index) = current[index]; }
    current_length as i64
}
