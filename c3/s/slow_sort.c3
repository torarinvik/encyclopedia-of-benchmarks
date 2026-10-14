module slow_sort;

fn void slow_sort_range(long* values, usz first, usz last) {
    if (first >= last) return;
    usz middle = first + (last - first) / 2;
    slow_sort_range(values, first, middle);
    slow_sort_range(values, middle + 1, last);
    if (values[last] < values[middle]) {
        long temporary = values[last]; values[last] = values[middle]; values[middle] = temporary;
    }
    slow_sort_range(values, first, last - 1);
}

fn void slow_sort(long* values, usz length) @export("slow_sort") {
    if (length > 1) slow_sort_range(values, 0, length - 1);
}
