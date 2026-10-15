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

    let mut previous_devices = 0i64;
    let mut beams = 0i64;
    for row in 0..rows {
        let mut devices = 0i64;
        for column in 0..columns {
            let cell = values[2 + row * columns + column];
            if cell != 48 && cell != 49 { return -1; }
            if cell == 49 { devices += 1; }
        }
        if devices != 0 {
            beams += devices * previous_devices;
            previous_devices = devices;
        }
    }
    beams
}
