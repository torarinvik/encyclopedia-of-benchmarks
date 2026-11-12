// Clean-room bounded implementation of the Library Checker sequence-counting task.
package number_of_increasing_sequences_between_two_sequences

import "core:c"

MAX_N :: 64
MAX_M :: 64
MAX_INPUT_LENGTH :: 130
MODULUS :: i64(998244353)

@(export)
number_of_increasing_sequences_between_two_sequences :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M do return -1
    n := int(input[0])
    m := int(input[1])
    if int(length) != 2 + 2 * n do return -1
    lower: [MAX_N]i64 = {}
    upper: [MAX_N]i64 = {}
    for position := 0; position < n; position += 1 {
        lower[position] = input[2 + position]
        upper[position] = input[2 + n + position]
        if lower[position] < 0 || lower[position] >= upper[position] || upper[position] > i64(m) do return -1
    }
    previous: [MAX_M]i64 = {}
    current: [MAX_M]i64 = {}
    for value := int(lower[0]); value < int(upper[0]); value += 1 do previous[value] = 1
    for position := 1; position < n; position += 1 {
        prefix := i64(0)
        for value := 0; value < m; value += 1 {
            prefix += previous[value]
            if prefix >= MODULUS do prefix -= MODULUS
            current[value] = 0
            if lower[position] <= i64(value) && i64(value) < upper[position] do current[value] = prefix
        }
        for value := 0; value < m; value += 1 do previous[value] = current[value]
    }
    answer := i64(0)
    for value := 0; value < m; value += 1 {
        answer += previous[value]
        if answer >= MODULUS do answer -= MODULUS
    }
    return answer
}
