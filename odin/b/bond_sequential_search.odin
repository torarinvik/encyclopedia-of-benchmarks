package bond_sequential_search

import "core:c"

MAX_N :: 64
MAX_VALUE :: 255
ABSENT_CODE :: i64(64)
PACK_BASE :: i64(65)

@(export, link_name="bond_sequential_search")
bond_sequential_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > c.size_t(MAX_N + 4) do return -1
    count_value := input[0]
    key_a := input[1]
    key_b := input[2]
    if count_value < 0 || count_value > MAX_N || length != c.size_t(count_value + 3) do return -1
    if key_a < 0 || key_a > MAX_VALUE || key_b < 0 || key_b > MAX_VALUE || key_a == key_b do return -1

    count := int(count_value)
    for i := 0; i < count; i += 1 {
        value := input[i + 3]
        if value < 0 || value > MAX_VALUE do return -1
    }

    index_a := ABSENT_CODE
    index_b := ABSENT_CODE
    composite := key_a | key_b
    for i := 0; i < count && (index_a == ABSENT_CODE || index_b == ABSENT_CODE); i += 1 {
        value := input[i + 3]
        if (value & composite) != value do continue
        if index_a == ABSENT_CODE && value == key_a do index_a = i64(i)
        if index_b == ABSENT_CODE && value == key_b do index_b = i64(i)
    }
    return index_a * PACK_BASE + index_b
}
