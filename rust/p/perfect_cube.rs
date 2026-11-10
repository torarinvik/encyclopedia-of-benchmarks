/// Test whether a signed value is an exact integer cube.
#[no_mangle]
pub extern "C" fn perfect_cube(value: i64) -> i64 {
    if !(-1_000_000_000_000..=1_000_000_000_000).contains(&value) { return -1; }
    let target = value.unsigned_abs();
    if target < 2 { return 1; }
    let root_limit = if target <= 1000 { 10 }
        else if target <= 1000000 { 100 }
        else if target <= 1000000000 { 1000 }
        else { 10000 };
    let mut low = 1_u64;
    let mut high = (target / 2).min(root_limit);
    while low <= high {
        let middle = (low + high) >> 1;
        let cube = middle * middle * middle;
        if cube == target { return 1; }
        if cube < target {
            if middle == high { return 0; }
            low = middle + 1;
        } else {
            if middle == low { return 0; }
            high = middle - 1;
        }
    }
    0
}
