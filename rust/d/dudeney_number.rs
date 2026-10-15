/// Test whether n is a positive Dudeney number: cube root equals digit sum.
#[no_mangle]
pub extern "C" fn dudeney_number(number: i64) -> i64 {
    if number <= 0 || number > i32::MAX as i64 { return -1; }
    let mut low = 1_i64;
    let mut high = 1290_i64;
    let mut root = 0_i64;
    while low <= high {
        let middle = low + (high - low) / 2;
        let cube = middle * middle * middle;
        if cube == number { root = middle; break; }
        if cube < number { low = middle + 1; }
        else { high = middle - 1; }
    }
    if root == 0 { return 0; }
    let mut remaining = number;
    let mut sum = 0_i64;
    while remaining > 0 {
        sum += remaining % 10;
        remaining /= 10;
    }
    if sum == root { 1 } else { 0 }
}
