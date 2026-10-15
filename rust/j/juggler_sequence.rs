/// Encode the Juggler sequence through its first 1 as little-endian u32 values.
fn floor_sqrt(value: i64) -> i64 {
    let (mut low, mut high) = (0i64, value + 1);
    while high - low > 1 {
        let middle = low + (high - low) / 2;
        if middle <= value / middle { low = middle; } else { high = middle; }
    }
    low
}

#[no_mangle]
pub extern "C" fn juggler_sequence(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=25).contains(&value) { return -1; }
    let mut sequence = [0i64; 16];
    let mut count = 1usize;
    sequence[0] = value;
    while sequence[count - 1] != 1 {
        let current = sequence[count - 1];
        sequence[count] = if current % 2 == 0 { floor_sqrt(current) }
            else { floor_sqrt(current * current * current) };
        count += 1;
    }
    let required = count * 4;
    if output.is_null() || output_capacity < required { return -2; }
    for index in 0..count {
        let term = sequence[index] as u32;
        for byte in 0..4 {
            unsafe { output.add(4 * index + byte).write((term >> (8 * byte)) as u8); }
        }
    }
    required as i64
}
