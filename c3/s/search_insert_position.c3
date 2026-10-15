module search_insert_position;

// Return the lower-bound position in a strictly increasing signed 32-bit array.
fn long search_insert_position(long* input, usz length) @export("search_insert_position") {
    if (length < 1 || length > 257 || input == null) return -1;
    long target = input[0];
    if (target < -2147483648 || target > 2147483647) return -1;
    for (usz index = 1; index < length; index++) {
        if (input[index] < -2147483648 || input[index] > 2147483647) return -1;
        if (index > 1 && input[index - 1] >= input[index]) return -1;
    }
    usz low = 0;
    usz high = length - 1;
    while (low < high) {
        usz middle = low + (high - low) / 2;
        if (input[middle + 1] < target) { low = middle + 1; }
        else { high = middle; }
    }
    return (long)low;
}
