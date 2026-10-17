const MAX_REQUESTS: usize = 64;

#[no_mangle]
pub unsafe extern "C" fn shortest_seek_time_first(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > 2 + MAX_REQUESTS { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let initial_track = input[0];
    let request_count = input[1];
    if !(0..=255).contains(&initial_track) ||
        !(0..=MAX_REQUESTS as i64).contains(&request_count) ||
        length != 2 + request_count as usize { return -1; }
    if input[2..].iter().any(|&request| !(0..=255).contains(&request)) { return -1; }
    if output.is_null() || capacity < request_count as usize { return -2; }

    let mut serviced = [false; MAX_REQUESTS];
    let mut current = initial_track;
    for step in 0..request_count as usize {
        let mut best = MAX_REQUESTS;
        let mut best_distance = 256i64;
        for i in 0..request_count as usize {
            if serviced[i] { continue; }
            let distance = (current - input[2 + i]).abs();
            if distance < best_distance { best = i; best_distance = distance; }
        }
        let selected = input[2 + best];
        *output.add(step) = selected as u8;
        serviced[best] = true;
        current = selected;
    }
    request_count
}
