module peak_index_in_mountain_array;

const usz MAX_ARRAY_LENGTH = 100000;

// Find the peak of a strict mountain array with binary search.
fn long peak_index_in_mountain_array(long* values, usz length) @export("peak_index_in_mountain_array") {
    if (values == null || length < 3 || length > MAX_ARRAY_LENGTH) { return -1; }
    usz low = 0;
    usz high = length - 1;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (values[middle] < values[middle + 1]) { low = middle + 1; }
        else { high = middle; }
    }
    if (low == 0 || low + 1 == length) { return -1; }
    return (long)low;
}
