module mex;

const usz MAX_VALUES = 100000;

fn void sift_down(long* values, usz root_start, usz end) {
    usz root = root_start;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn void heap_sort(long* values, usz length) {
    for (usz start = length / 2; start > 0; start--) sift_down(values, start - 1, length);
    for (usz end = length; end > 1; end--) {
        long temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}

fn long mex(long* input, usz length) @export("mex") {
    if (input == null || length < 1 || length > MAX_VALUES + 1) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > (long)MAX_VALUES || length != (usz)count_value + 1) return -1;
    usz count = (usz)count_value;
    long[MAX_VALUES] values;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648 || value > 2147483647) return -1;
        values[index] = value;
    }
    heap_sort(&values[0], count);
    long candidate = 0;
    for (usz index = 0; index < count; index++) {
        if (values[index] == candidate) candidate++;
    }
    return candidate;
}
