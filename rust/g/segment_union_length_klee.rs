const MAX_N: i64 = 64;
const MAX_INPUT_LENGTH: usize = 130;

#[no_mangle]
pub unsafe extern "C" fn segment_union_length_klee(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(0..=MAX_N).contains(&n_value) { return -1; }
    let n = n_value as usize;
    if length != 1 + 2 * n { return -1; }
    let mut events = [0i64; 128];
    for i in 0..n {
        let left = values[1 + 2 * i];
        let right = values[2 + 2 * i];
        if left < -1000 || left > right || right > 1000 { return -1; }
        events[2 * i] = 2 * (left + 1000);
        events[2 * i + 1] = 2 * (right + 1000) + 1;
    }
    let event_count = 2 * n;
    if event_count == 0 { return 0; }
    events[..event_count].sort_unstable();
    let mut active = 0i64;
    let mut total = 0i64;
    let mut previous = 0i64;
    let mut index = 0;
    while index < event_count {
        let coordinate_code = events[index] / 2;
        let coordinate = coordinate_code - 1000;
        if index > 0 && active > 0 { total += coordinate - previous; }
        let mut delta = 0i64;
        while index < event_count && events[index] / 2 == coordinate_code {
            delta += if events[index] % 2 == 0 { 1 } else { -1 };
            index += 1;
        }
        active += delta;
        previous = coordinate;
    }
    total
}
