module sort_the_odd;

const usz MAX_LENGTH = 256;
const long MIN_VALUE = -1000000;
const long MAX_VALUE = 1000000;
const long CHECKSUM_OFFSET = 1000001;

fn void sift_down(long* values, usz root, usz end) {
    usz parent = root;
    while (parent * 2 + 1 < end) {
        usz child = parent * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[parent] >= values[child]) break;
        long temporary = values[parent];
        values[parent] = values[child];
        values[child] = temporary;
        parent = child;
    }
}

fn void heap_sort(long* values, usz length) {
    usz start = length / 2;
    while (start > 0) {
        start--;
        sift_down(values, start, length);
    }
    usz end = length;
    while (end > 1) {
        end--;
        long temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        sift_down(values, 0, end);
    }
}

fn long sort_the_odd_benchmark(long* values, usz length) @export("sort_the_odd_benchmark") {
    if (length > MAX_LENGTH || (values == null && length != 0)) return -1;

    long[256] odds;
    usz odd_count = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < MIN_VALUE || value > MAX_VALUE) return -1;
        if (value % 2 != 0) {
            odds[odd_count] = value;
            odd_count++;
        }
    }
    if (odd_count > 1) heap_sort(odds, odd_count);

    usz odd_index = 0;
    long checksum = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value % 2 != 0) {
            value = odds[odd_index];
            odd_index++;
        }
        checksum += (long)(i + 1) * (value + CHECKSUM_OFFSET);
    }
    return checksum;
}
