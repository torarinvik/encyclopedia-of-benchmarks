/// Sum both circular routes and return the shorter one.
#[no_mangle]
pub extern "C" fn distance_between_bus_stops(input: *const i64, length: usize) -> i64 {
    if !(3..=66).contains(&length) {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let stop_count = length - 2;
    let start_value = input[0];
    let destination_value = input[1];
    if start_value < 0
        || destination_value < 0
        || start_value >= stop_count as i64
        || destination_value >= stop_count as i64
    {
        return -1;
    }

    let start = start_value as usize;
    let destination = destination_value as usize;
    let low = start.min(destination);
    let high = start.max(destination);
    let mut total = 0i64;
    let mut direct = 0i64;
    for index in 0..stop_count {
        let distance = input[index + 2];
        if !(0..=1_000_000).contains(&distance) {
            return -1;
        }
        total += distance;
        if index >= low && index < high {
            direct += distance;
        }
    }
    let other = total - direct;
    direct.min(other)
}
