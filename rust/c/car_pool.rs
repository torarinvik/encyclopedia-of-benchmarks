#[no_mangle]
pub unsafe extern "C" fn car_pool(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 194 { return -1; }
    if *input < 0 || *input > 1000 || *input.add(1) < 0 || *input.add(1) > 64 { return -1; }
    let capacity = *input;
    let trip_count = *input.add(1) as usize;
    if length != 2 + 3 * trip_count { return -1; }

    let mut events = [0_i32; 1001];
    for trip in 0..trip_count {
        let offset = 2 + 3 * trip;
        let passengers = *input.add(offset);
        let origin = *input.add(offset + 1);
        let destination = *input.add(offset + 2);
        if !(1..=1000).contains(&passengers) || origin < 0 || origin >= destination || destination > 1000 {
            return -1;
        }
        events[origin as usize] += passengers as i32;
        events[destination as usize] -= passengers as i32;
    }

    let mut occupants = 0_i32;
    for position in 0..1000 {
        occupants += events[position];
        if occupants as i64 > capacity { return 0; }
    }
    1
}
