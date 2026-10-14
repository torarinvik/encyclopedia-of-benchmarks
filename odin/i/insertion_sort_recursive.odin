package insertion_sort_recursive

import "core:c"

insertion_sort_prefix :: proc "contextless" (values: [^]i64, length: c.size_t) {
    if length <= 1 do return
    insertion_sort_prefix(values, length - 1)
    key := values[length - 1]
    position := length - 1
    for position > 0 && values[position - 1] > key {
        values[position] = values[position - 1]
        position -= 1
    }
    values[position] = key
}

@(export)
insertion_sort_recursive :: proc "c" (values: [^]i64, length: c.size_t) {
    insertion_sort_prefix(values, length)
}
