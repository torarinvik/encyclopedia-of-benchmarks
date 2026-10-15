module array_pair_sum;

const MAX_LENGTH = 4096;

fn void sift_down(long* values, usz root_value, usz count) {
    usz root = root_value;
    while (root * 2 + 1 < count) {
        usz child = root * 2 + 1;
        if (child + 1 < count && values[child] < values[child + 1]) { child++; }
        if (values[root] >= values[child]) { return; }
        long temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

// Sort signed 32-bit values and sum the first of every adjacent pair.
fn long array_pair_sum(long* input, usz length) @export("array_pair_sum") {
    if (length > MAX_LENGTH || length % 2 != 0 || (length != 0 && input == null)) { return -1; }
    long[MAX_LENGTH] values;
    for (usz index = 0; index < length; index++) {
        if (input[index] < -2147483648L || input[index] > 2147483647L) { return -1; }
        values[index] = input[index];
    }
    for (usz start = length / 2; start > 0; start--) { sift_down(&values[0], start - 1, length); }
    for (usz end = length; end > 1; end--) {
        long temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(&values[0], 0, end - 1);
    }
    long total = 0;
    for (usz index = 0; index < length; index += 2) { total += values[index]; }
    return total;
}
