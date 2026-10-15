module first_bad_version;

// Find the first bad version with a lower-bound binary search.
fn long first_bad_version(ulong version_count, ulong first_bad) @export("first_bad_version") {
    if (version_count == 0 || version_count > 2147483647 || first_bad == 0 || first_bad > version_count) {
        return -1;
    }

    ulong low = 1;
    ulong high = version_count;
    while (low < high) {
        ulong middle = low + (high - low) / 2;
        if (middle >= first_bad) high = middle;
        else low = middle + 1;
    }
    return (long)low;
}
