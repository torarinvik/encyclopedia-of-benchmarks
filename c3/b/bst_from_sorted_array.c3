fn long bst_shape(usz start, usz end, usz heap_index) {
    if (start >= end) return 0;
    usz middle = start + (end - start - 1) / 2;
    return (1L << heap_index)
         | bst_shape(start, middle, 2 * heap_index + 1)
         | bst_shape(middle + 1, end, 2 * heap_index + 2);
}

fn long bst_from_sorted_array(long* values, usz length) @export("bst_from_sorted_array") {
    if (length > 15 || (length != 0 && values == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < -2147483648L || values[index] > 2147483647L) return -1;
        if (index != 0 && values[index - 1] >= values[index]) return -1;
    }
    return bst_shape(0, length, 0);
}
