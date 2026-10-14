module bubble_sort_recursive;

const MAX_VALUES = 256;

fn void bubble_sort_recursive_impl(long* values, usz length) {
    if (length <= 1) return;
    bool swapped = false;
    for (usz index = 0; index + 1 < length; index++) {
        if (values[index] > values[index + 1]) {
            long temporary = values[index];
            values[index] = values[index + 1];
            values[index + 1] = temporary;
            swapped = true;
        }
    }
    if (swapped) bubble_sort_recursive_impl(values, length - 1);
}

fn void bubble_sort_recursive(long* values, usz length) @export("bubble_sort_recursive") {
    if (length <= MAX_VALUES) bubble_sort_recursive_impl(values, length);
}
