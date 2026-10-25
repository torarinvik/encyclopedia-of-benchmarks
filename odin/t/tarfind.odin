// Bounded clean-room TAR-header filename search benchmark.
// Embench-IoT source declares MIT; see the package attribution.
// SPDX-License-Identifier: MIT
package tarfind

import "core:c"

MAX_RECORDS :: 35
MAX_QUERIES :: 5
MIN_NAME_LENGTH :: 5
MAX_NAME_LENGTH :: 39
MAX_INPUT_LENGTH :: 2 + MAX_RECORDS * (1 + MAX_NAME_LENGTH) + MAX_QUERIES * (1 + MAX_NAME_LENGTH)

@(export)
tarfind :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
    capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_RECORDS || input[1] < 1 || input[1] > MAX_QUERIES do return -1
    record_count := int(input[0])
    query_count := int(input[1])
    record_offsets: [MAX_RECORDS]c.size_t = {}
    record_lengths: [MAX_RECORDS]c.size_t = {}
    query_offsets: [MAX_QUERIES]c.size_t = {}
    query_lengths: [MAX_QUERIES]c.size_t = {}
    staged: [MAX_QUERIES]u8 = {}
    position := 2
    total := int(length)

    for i := 0; i < record_count; i += 1 {
        if position >= total do return -1
        raw_length := input[position]
        position += 1
        if raw_length < MIN_NAME_LENGTH || raw_length > MAX_NAME_LENGTH do return -1
        name_length := int(raw_length)
        if name_length > total - position do return -1
        record_offsets[i] = c.size_t(position)
        record_lengths[i] = c.size_t(name_length)
        for j := 0; j < name_length; j += 1 {
            value := input[position + j]
            if value < 65 || value > 90 do return -1
        }
        position += name_length
    }
    for i := 0; i < query_count; i += 1 {
        if position >= total do return -1
        raw_length := input[position]
        position += 1
        if raw_length < MIN_NAME_LENGTH || raw_length > MAX_NAME_LENGTH do return -1
        name_length := int(raw_length)
        if name_length > total - position do return -1
        query_offsets[i] = c.size_t(position)
        query_lengths[i] = c.size_t(name_length)
        for j := 0; j < name_length; j += 1 {
            value := input[position + j]
            if value < 65 || value > 90 do return -1
        }
        position += name_length
    }
    if position != total do return -1
    if output == nil || capacity < c.size_t(query_count) do return -2

    for q := 0; q < query_count; q += 1 {
        found: i64 = -1
        for i := 0; i < record_count; i += 1 {
            if record_lengths[i] != query_lengths[q] do continue
            j := 0
            for j < int(query_lengths[q]) &&
                input[int(record_offsets[i])+j] == input[int(query_offsets[q])+j] {
                j += 1
            }
            if j == int(query_lengths[q]) {
                found = i64(i)
                break
            }
        }
        staged[q] = if found < 0 then 255 else u8(found)
    }
    for q := 0; q < query_count; q += 1 { output[q] = staged[q] }
    i64(query_count)
}
