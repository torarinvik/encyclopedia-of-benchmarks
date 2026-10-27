const MAX_INPUT: usize = 4;
const MAX_TRIPS: usize = 32;

#[no_mangle]
pub unsafe extern "C" fn ski_rental_deterministic(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (rent, purchase, trips) = (values[0], values[1], values[2]);
    if length != 3 || !(1..=32).contains(&rent) || !(1..=64).contains(&purchase) || !(0..=MAX_TRIPS as i64).contains(&trips) {
        return -1;
    }
    let count = trips as usize;
    if output.is_null() || capacity < count { return -2; }
    let mut actions = [0u8; MAX_TRIPS];
    let threshold = purchase / rent;
    for trip in 0..count {
        actions[trip] = if (trip as i64) < threshold { 0 } else if (trip as i64) == threshold { 1 } else { 2 };
    }
    std::ptr::copy_nonoverlapping(actions.as_ptr(), output, count);
    count as i64
}
