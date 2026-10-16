module recursive_linear_search;

const long MAX_COUNT = 64;
const usz MAX_INPUT_LENGTH = 67;

fn long search_from_end(long* items, usz count, long target) {
    if (count == 0) return -1;
    if (items[count - 1] == target) return (long)(count - 1);
    return search_from_end(items, count - 1, target);
}

fn long recursive_linear_search(long* values, usz length) @export("recursive_linear_search") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = values[0];
    long target = values[1];
    if (count_value < 1 || count_value > MAX_COUNT) return -1;
    usz count = (usz)count_value;
    if (length != count + 2) return -1;
    return search_from_end(values + 2, count, target);
}
