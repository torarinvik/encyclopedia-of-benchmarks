module find_min_iterator;

fn long find_min_iterator(long* input, usz length) @export("find_min_iterator") {
    if (input == null || length < 1 || length > 129) return -1;
    if (input[0] < 0 || input[0] > 128 || length != input[0].usz() + 1) return -1;
    usz count = input[0].usz();
    if (count == 0) return -1;
    long minimum = 2147483647;
    for (usz i = 0; i < count; i++) {
        long value = input[i + 1];
        if (value < 0 || value > 2147483647) return -1;
        if (value < minimum) minimum = value;
    }
    return minimum;
}
