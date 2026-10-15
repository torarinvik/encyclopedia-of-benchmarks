#[no_mangle]
pub extern "C" fn kolakoski_sequence(index: i64) -> i64 {
    if !(0..=63).contains(&index) { return -1; }
    if index == 0 { return 1; }
    if index <= 2 { return 2; }

    let mut encoded = 6u64;
    let mut read_bit = 4u64;
    let mut write_bit = 8u64;
    let target = index as u64;
    let mut current_index = 3u64;
    let mut next_element = 1i64;

    while current_index <= target {
        let run_length = 1 + (encoded / read_bit) % 2;
        let mut emitted = 0u64;
        while emitted < run_length {
            if next_element == 2 { encoded += write_bit; }
            if current_index == target { return next_element; }
            current_index += 1;
            write_bit *= 2;
            emitted += 1;
        }
        read_bit *= 2;
        next_element = 3 - next_element;
    }
    -1
}
