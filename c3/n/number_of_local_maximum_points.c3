module number_of_local_maximum_points;

const long MAX_LENGTH = 4096L;
const long INT32_MIN_VALUE = -2147483648L;
const long INT32_MAX_VALUE = 2147483647L;

fn bool is_local_maximum(long* values, long length, long index) {
    if (index == 0L) return values[0] > values[1];
    if (index == length - 1L) return values[index] > values[index - 1L];
    return values[index] > values[index - 1L] && values[index] > values[index + 1L];
}

fn long count_range(long* values, long length, long start, long end) {
    if (start == end) return is_local_maximum(values, length, start) ? 1L : 0L;
    long middle = (start + end) / 2L;
    return count_range(values, length, start, middle) + count_range(values, length, middle + 1L, end);
}

// Count strict local maxima using the pinned recursive partition.
fn long number_of_local_maximum_points(long* values, usz length) @export("number_of_local_maximum_points") {
    if (values == null || length == 0 || length > MAX_LENGTH) return -1L;
    for (usz i = 0; i < length; i++) {
        if (values[i] < INT32_MIN_VALUE || values[i] > INT32_MAX_VALUE) return -1L;
    }
    if (length == 1) return 0L; // Source compares the sole element with undefined.
    return count_range(values, (long)length, 0L, (long)length - 1L);
}
