/// Minimum time to cross two assembly lines using station-by-station dynamic programming.
#[no_mangle]
pub extern "C" fn assembly_line_scheduling(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 7 { return -1; }
    let input = unsafe { core::slice::from_raw_parts(values, length) };
    if !(1..=64).contains(&input[0]) { return -1; }
    let n = input[0] as usize;
    if length != 4 * n + 3 || input.iter().any(|&value| !(0..=1000).contains(&value)) {
        return -1;
    }

    let a0 = 1;
    let a1 = a0 + n;
    let t0 = a1 + n;
    let t1 = t0 + n - 1;
    let entry = t1 + n - 1;
    let mut line0 = input[entry] + input[a0];
    let mut line1 = input[entry + 1] + input[a1];
    for station in 1..n {
        let stay0 = line0 + input[a0 + station];
        let switch0 = line1 + input[t1 + station - 1] + input[a0 + station];
        let stay1 = line1 + input[a1 + station];
        let switch1 = line0 + input[t0 + station - 1] + input[a1 + station];
        line0 = stay0.min(switch0);
        line1 = stay1.min(switch1);
    }
    let answer = (line0 + input[entry + 2]).min(line1 + input[entry + 3]);
    if output.is_null() || output_capacity < 4 { return -2; }
    let bytes = (answer as i32).to_le_bytes();
    for (index, byte) in bytes.into_iter().enumerate() {
        unsafe { *output.add(index) = byte; }
    }
    4
}
