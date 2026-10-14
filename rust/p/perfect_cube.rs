/// Test whether a signed value is an exact integer cube.
#[no_mangle]
pub extern "C" fn perfect_cube(value: i64) -> i64 {
    if !(-1_000_000_000_000..=1_000_000_000_000).contains(&value) { return -1; }
    let target = value.abs();
    let mut low = 0i64;
    let mut high = 10_000i64;
    while low <= high {
        let middle = low + (high - low) / 2;
        let cube = middle * middle * middle;
        if cube == target { return 1; }
        if cube < target { low = middle + 1; }
        else { high = middle - 1; }
    }
    0
}
