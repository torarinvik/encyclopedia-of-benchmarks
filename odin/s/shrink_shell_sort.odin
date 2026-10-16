package shrink_shell_sort

import "core:c"

// Shell sort using the pinned Python 1.3 gap shrink factor.
@(export)
shrink_shell_sort :: proc "c" (values: [^]i64, length: c.size_t) {
    gap := length
    for gap > 1 {
        gap = c.size_t(f64(gap) / 1.3)
        for index := gap; index < length; index += 1 {
            key := values[index]
            position := index
            for position >= gap && values[position - gap] > key {
                values[position] = values[position - gap]
                position -= gap
            }
            values[position] = key
        }
    }
}
