const MAX_LENGTH: usize = 64;
const UNREACHABLE: i64 = 1_000_000_000_000;

#[no_mangle]
pub unsafe extern "C" fn min_number_of_jumps(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|&value| !(0..=MAX_LENGTH as i64).contains(&value)) { return -1; }
    let mut jumps = [UNREACHABLE; MAX_LENGTH];
    jumps[0] = 0;
    for i in 1..length {
        for j in 0..i {
            if values[j] + j as i64 >= i as i64 && jumps[j] + 1 < jumps[i] {
                jumps[i] = jumps[j] + 1;
            }
        }
    }
    jumps[length - 1]
}
