module find_min_rotated_sorted_array;

// Return the minimum in a rotation of a strictly increasing i64 array.
fn long find_min_rotated_sorted_array(long* values, usz length) @export("find_min_rotated_sorted_array") {
    if (length < 1 || length > 256 || values == null) return -1;
    usz low = 0;
    usz high = length - 1;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (values[middle] <= values[high]) { high = middle; }
        else { low = middle + 1; }
    }
    return values[low];
}
