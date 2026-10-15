/// Find the first bad version with a lower-bound binary search.
export fn first_bad_version(version_count: u64, first_bad: u64) i64 {
    if (version_count == 0 or version_count > 2_147_483_647 or
        first_bad == 0 or first_bad > version_count) return -1;

    var low: u64 = 1;
    var high: u64 = version_count;
    while (low < high) {
        const middle = low + (high - low) / 2;
        if (middle >= first_bad) high = middle else low = middle + 1;
    }
    return @intCast(low);
}
