// Clean-room bounded lexicographic successor for a one-type Dyck word.
package balanced_parenthesis_successor

import "core:c"

MAX_PAIRS :: 10
MAX_INPUT_LENGTH :: 21
MAX_OUTPUT_BYTES :: 20

@(export)
balanced_parenthesis_successor :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
    pair_value := input[0]
    if pair_value < 1 || pair_value > MAX_PAIRS do return -1
    pairs, sequence_length := int(pair_value), 2*int(pair_value)
    if length != c.size_t(1+sequence_length) do return -1
    symbols: [MAX_OUTPUT_BYTES]int
    balance := 0
    for i := 0; i < sequence_length; i += 1 {
        symbol := input[1+i]
        if symbol != 0 && symbol != 1 do return -1
        symbols[i] = int(symbol)
        if symbol == 0 do balance += 1 else do balance -= 1
        if balance < 0 do return -1
    }
    if balance != 0 do return -1
    if output == nil || capacity < c.size_t(sequence_length) do return -2

    staged: [MAX_OUTPUT_BYTES]u8
    reverse_depth := 0
    cursor := sequence_length
    for cursor > 0 {
        cursor -= 1
        if symbols[cursor] == 0 do reverse_depth -= 1 else do reverse_depth += 1
        if symbols[cursor] == 0 && reverse_depth > 0 {
            reverse_depth -= 1
            suffix_length := sequence_length - cursor - 1
            opening_count := (suffix_length - reverse_depth) / 2
            closing_count := suffix_length - opening_count
            for j := 0; j < cursor; j += 1 { staged[j] = if symbols[j] == 0 { 40 } else { 41 } }
            staged[cursor] = 41
            position := cursor + 1
            for j := 0; j < opening_count; j += 1 { staged[position] = 40; position += 1 }
            for j := 0; j < closing_count; j += 1 { staged[position] = 41; position += 1 }
            for j := 0; j < sequence_length; j += 1 { output[j] = staged[j] }
            return i64(sequence_length)
        }
    }
    return -3
}
