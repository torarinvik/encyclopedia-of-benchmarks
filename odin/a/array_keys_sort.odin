package array_keys_sort

import "core:c"

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}
compare_rows :: proc "contextless" (left, right: [^]i64, keys: [^]i64, key_count: int, ascending: bool) -> int {
    for key := 0; key < key_count; key += 1 {
        field := int(keys[key] - 1)
        a, b := left[field], right[field]
        if a < b { return if ascending { -1 } else { 1 } }
        if a > b { return if ascending { 1 } else { -1 } }
    }
    return 0
}
@(export)
array_keys_sort :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 8 || length > 263 do return -1
    raw_count, raw_key_count, order := values[0], values[1], values[2]
    if raw_count < 1 || raw_count > 64 || raw_key_count < 1 || raw_key_count > 4 || (order != 0 && order != 1) do return -1
    count, key_count := int(raw_count), int(raw_key_count)
    if length != c.size_t(3 + key_count + 4 * count) do return -1
    keys := &values[3]
    for index := 0; index < key_count; index += 1 {
        if keys[index] < 1 || keys[index] > 4 do return -1
        for previous := 0; previous < index; previous += 1 { if keys[index] == keys[previous] do return -1 }
    }
    rows: [256]i64
    rows_start := 3 + key_count
    for index := 0; index < 4 * count; index += 1 {
        value := values[rows_start + index]
        if value < -1000 || value > 1000 do return -1
        rows[index] = value
    }
    for left := 0; left < count; left += 1 {
        for right := left + 1; right < count; right += 1 {
            if compare_rows(&rows[left * 4], &rows[right * 4], keys, key_count, true) == 0 do return -1
        }
    }
    byte_count := 32 * count
    if output == nil || output_capacity < c.size_t(byte_count) do return -2
    for index := 1; index < count; index += 1 {
        temporary: [4]i64
        for column := 0; column < 4; column += 1 { temporary[column] = rows[index * 4 + column] }
        position := index
        for position > 0 && compare_rows(&rows[(position - 1) * 4], &temporary[0], keys, key_count, order == 1) > 0 {
            for column := 0; column < 4; column += 1 { rows[position * 4 + column] = rows[(position - 1) * 4 + column] }
            position -= 1
        }
        for column := 0; column < 4; column += 1 { rows[position * 4 + column] = temporary[column] }
    }
    for index := 0; index < 4 * count; index += 1 { store_i64_le(output, 8 * index, rows[index]) }
    return i64(byte_count)
}
