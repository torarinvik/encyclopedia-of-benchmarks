package junta_test_partition_binary_search

import "core:c"

MAX_N :: 8
ROUNDS :: 24
MAX_GROUPS :: 8
MAX_OUTPUT_WORDS :: 7

truth_at :: proc(table: [^]u64, point: u32) -> i64 {
    return i64((table[int(point/64)] >> (point%64)) & 1)
}

put_i64 :: proc(output: [^]u8, offset: int, value: i64) {
    bits := transmute(u64)value
    for byte := 0; byte < 8; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
junta_test_partition_binary_search :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 40 do return -1
    n64, groups64, words64 := input[0], input[1], input[2]
    if n64 < 1 || n64 > MAX_N || groups64 < 1 || groups64 > n64 do return -1
    n, group_count := int(n64), int(groups64)
    domain := 1 << n
    truth_words := (domain + 63) / 64
    if words64 != i64(truth_words) do return -1
    table_at := 3
    labels_at := table_at + truth_words
    tape_at := labels_at + n
    if length != c.size_t(tape_at + ROUNDS) do return -1

    table: [4]u64
    for word := 0; word < truth_words; word += 1 { table[word] = transmute(u64)input[table_at+word] }
    tail_bits := domain % 64
    if tail_bits != 0 && (table[truth_words-1] >> tail_bits) != 0 do return -1

    group_masks: [MAX_GROUPS]u32 = {}
    groups_seen: u32 = 0
    for coordinate := 0; coordinate < n; coordinate += 1 {
        group := input[labels_at+coordinate]
        if group < 0 || group >= groups64 do return -1
        group_masks[int(group)] |= u32(1) << coordinate
        groups_seen |= u32(1) << int(group)
    }
    if groups_seen != ((u32(1) << group_count)-1) do return -1
    pair_limit := u64(1) << (2*n)
    for round := 0; round < ROUNDS; round += 1 {
        pair := input[tape_at+round]
        if pair < 0 || transmute(u64)pair >= pair_limit do return -1
    }

    result: [MAX_OUTPUT_WORDS]i64
    event_rounds: [2]i64
    event_groups: [2]i64
    found, query_count := 0, 0
    all_coordinates := (u32(1) << n)-1
    active := all_coordinates
    for round := 0; round < ROUNDS; round += 1 {
        packed := transmute(u64)input[tape_at+round]
        x := u32(packed & u64(all_coordinates))
        y := u32((packed >> n) & u64(all_coordinates))
        hybrid := (x & ~active) | (y & active)
        left_value := truth_at(&table[0], x)
        right_value := truth_at(&table[0], hybrid)
        query_count += 2
        if left_value != right_value {
            candidates: [MAX_GROUPS]u8
            candidate_count := 0
            for group := 0; group < group_count; group += 1 {
                if (group_masks[group] & active) != 0 {
                    candidates[candidate_count] = u8(group)
                    candidate_count += 1
                }
            }
            left_endpoint, right_endpoint := x, hybrid
            for candidate_count > 1 {
                cut := candidate_count / 2
                low_mask: u32 = 0
                for i := 0; i < cut; i += 1 { low_mask |= group_masks[int(candidates[i])] }
                probe := (left_endpoint & ~low_mask) | (right_endpoint & low_mask)
                probe_value := truth_at(&table[0], probe)
                query_count += 1
                if probe_value != left_value {
                    right_endpoint = probe
                    candidate_count = cut
                } else {
                    left_endpoint = probe
                    left_value = probe_value
                    for i := cut; i < candidate_count; i += 1 { candidates[i-cut] = candidates[i] }
                    candidate_count -= cut
                }
            }
            selected := int(candidates[0])
            active &= ~group_masks[selected]
            event_rounds[found] = i64(round)
            event_groups[found] = i64(selected)
            found += 1
            if found > 1 do break
        }
    }

    result[0] = 0
    if found > 1 { result[0] = 1 }
    result[1], result[2] = i64(found), i64(query_count)
    for i := 0; i < found; i += 1 {
        result[3+2*i] = event_rounds[i]
        result[4+2*i] = event_groups[i]
    }
    result_words := 3 + 2*found
    result_bytes := result_words * 8
    if output == nil || capacity < c.size_t(result_bytes) do return -2
    for i := 0; i < result_words; i += 1 { put_i64(output, i*8, result[i]) }
    return i64(result_bytes)
}
