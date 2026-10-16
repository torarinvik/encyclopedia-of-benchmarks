module count_less_equal_in_sorted_array;

fn long count_less_equal_in_sorted_array(long* input, usz length) @export("count_less_equal_in_sorted_array") {
    if (input == null || length < 1 || length > 513) return -1;
    long key = input[0];
    if (key < -2147483648 || key > 2147483647) return -1;
    for (usz index = 1; index < length; index++) {
        long value = input[index];
        if (value < -2147483648 || value > 2147483647) return -1;
        if (index > 1 && input[index - 1] > value) return -1;
    }

    long left = 1;
    long right = (long)length - 1;
    long count = 0;
    while (left <= right) {
        long middle = left + (right - left) / 2;
        if (input[middle] > key) { right = middle - 1; }
        else {
            count = middle;
            left = middle + 1;
        }
    }
    return count;
}
