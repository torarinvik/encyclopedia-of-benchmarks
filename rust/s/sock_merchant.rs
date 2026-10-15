#[no_mangle]
pub unsafe extern "C" fn sock_merchant(colors: *const i64, length: usize) -> i64 {
    if length > 512 || (length > 0 && colors.is_null()) {
        return -1;
    }
    let mut counts = [0usize; 4096];
    for index in 0..length {
        let value = *colors.add(index);
        if !(0..=4095).contains(&value) {
            return -1;
        }
        counts[value as usize] += 1;
    }
    counts.iter().map(|count| (count / 2) as i64).sum()
}
