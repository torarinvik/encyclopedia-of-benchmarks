/// Recursively emit the canonical Tower of Hanoi move sequence.
fn emit_hanoi(disks: usize, source: u8, destination: u8, auxiliary: u8,
              output: *mut u8, position: usize) -> usize {
    if disks == 0 { return position; }
    let after_first = emit_hanoi(disks - 1, source, auxiliary, destination, output, position);
    unsafe {
        *output.add(after_first) = source;
        *output.add(after_first + 1) = destination;
    }
    emit_hanoi(disks - 1, auxiliary, destination, source, output, after_first + 2)
}

#[no_mangle]
pub extern "C" fn tower_of_hanoi(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length != 4 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if !(0..=12).contains(&values[0]) || values[1..].iter().any(|peg| !(0..=2).contains(peg)) {
        return -1;
    }
    if values[1] == values[2] || values[1] == values[3] || values[2] == values[3] { return -1; }
    let disks = values[0] as usize;
    let move_count = (1usize << disks) - 1;
    let required = move_count * 2;
    if output_capacity < required || (required != 0 && output.is_null()) { return -2; }
    emit_hanoi(disks, values[1] as u8, values[2] as u8, values[3] as u8, output, 0);
    move_count as i64
}
