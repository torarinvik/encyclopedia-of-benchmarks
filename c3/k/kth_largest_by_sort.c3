module kth_largest_by_sort;

const MAX_LENGTH = 512;

fn void sift_down(int* values, usz root_start, usz end) {
    usz root = root_start;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) { child++; }
        if (values[root] >= values[child]) { break; }
        int temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

// Sort a local copy with portable heapsort, then index from the end.
fn long kth_largest_by_sort(long* input, usz length) @export("kth_largest_by_sort") {
    if (input == null || length < 2 || length > MAX_LENGTH + 1) { return -1; }
    usz count = length - 1;
    if (input[0] < 1 || input[0] > (long)count) { return -1; }
    int[512] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) { return -1; }
        values[index] = (int)value;
    }
    for (usz start = count / 2; start > 0; start--) {
        sift_down(&values[0], start - 1, count);
    }
    for (usz end = count; end > 1; end--) {
        int temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(&values[0], 0, end - 1);
    }
    return values[count - (usz)input[0]];
}
