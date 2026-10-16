package count_less_equal_in_sorted_array

@(export)
count_less_equal_in_sorted_array :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 513 do return -1
    key := input[0]
    if key < -2_147_483_648 || key > 2_147_483_647 do return -1
    for index := 1; index < int(length); index += 1 {
        value := input[index]
        if value < -2_147_483_648 || value > 2_147_483_647 do return -1
        if index > 1 && input[index - 1] > value do return -1
    }

    left := 1
    right := int(length - 1)
    count := 0
    for left <= right {
        middle := left + (right - left) / 2
        if input[middle] > key {
            right = middle - 1
        } else {
            count = middle
            left = middle + 1
        }
    }
    return i64(count)
}
