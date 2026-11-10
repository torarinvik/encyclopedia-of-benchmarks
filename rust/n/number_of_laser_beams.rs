/// Count adjacent nonempty-row device pairs in a fixed-width binary bank.
const MAX_DIMENSION: usize = 64;
const MAX_CELLS: usize = MAX_DIMENSION * MAX_DIMENSION;

#[no_mangle]
pub extern "C" fn number_of_laser_beams(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_CELLS + 2 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    if values[0] < 1 || values[0] > MAX_DIMENSION as i64 ||
        values[1] < 1 || values[1] > MAX_DIMENSION as i64 { return -1; }
    let rows = values[0] as usize;
    let columns = values[1] as usize;
    if length != rows * columns + 2 { return -1; }

    let mut invalid_bits = 0u64;
    let mut previous_devices = 0u64;
    let mut beams = 0u64;
    for row in values[2..].chunks_exact(columns) {
        let mut devices = 0u64;
        for &cell in row {
            let byte = cell as u64;
            invalid_bits |= byte ^ 48;
            devices += byte & 1;
        }
        beams += devices * previous_devices;
        if devices != 0 { previous_devices = devices; }
    }
    if invalid_bits > 1 { return -1; }
    beams as i64
}
