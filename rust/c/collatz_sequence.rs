const MAX_START: i64 = 1_000_000;

fn next_term(value: i64) -> i64 {
    if value % 2 == 0 { value / 2 } else { 3 * value + 1 }
}

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn collatz_sequence(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length != 1 { return -1; }
    let start = *input;
    if !(1..=MAX_START).contains(&start) { return -1; }
    let mut current = start;
    let mut term_count = 1usize;
    while current != 1 { current = next_term(current); term_count += 1; }
    let required = term_count * 8;
    if output_capacity < required || output.is_null() { return -2; }
    current = start;
    let mut written = 0usize;
    loop {
        store_i64_le(output, written, current);
        written += 8;
        if current == 1 { break; }
        current = next_term(current);
    }
    written as i64
}
