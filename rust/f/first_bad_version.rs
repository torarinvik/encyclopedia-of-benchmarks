/// Find the first bad version with a lower-bound binary search.
#[no_mangle]
pub extern "C" fn first_bad_version(version_count: u64, first_bad: u64) -> i64 {
    if version_count == 0 || version_count > 2_147_483_647 ||
        first_bad == 0 || first_bad > version_count { return -1; }

    let (mut low, mut high) = (1u64, version_count);
    while low < high {
        let middle = low + (high - low) / 2;
        if middle >= first_bad { high = middle; }
        else { low = middle + 1; }
    }
    low as i64
}
