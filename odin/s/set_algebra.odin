package set_algebra

import "core:c"

Max_Set_Size :: 64
Max_Result_Size :: 2 * Max_Set_Size
Max_Input_Length :: 4 + 2 * Max_Set_Size

contains :: proc(values: [^]i64, count: usize, target: i64) -> bool {
    for i: usize = 0; i < count; i += 1 { if values[i] == target do return true }
    return false
}
bool_to_i64 :: proc(value: bool) -> i64 {
    if value do return 1
    return 0
}
is_subset :: proc(left: [^]i64, left_count: usize, right: [^]i64, right_count: usize) -> bool {
    if left_count > right_count do return false
    for i: usize = 0; i < left_count; i += 1 { if !contains(right, right_count, left[i]) do return false }
    return true
}
put_i64_le :: proc(value: i64, output: [^]u8, offset: usize) {
    bits := transmute(u64)value
    for byte: usize = 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
set_algebra :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > Max_Input_Length do return -1
    operation, left_raw, right_raw, query_key := input[0], input[1], input[2], input[3]
    if operation < 0 || operation > 8 || left_raw < 0 || left_raw > Max_Set_Size || right_raw < 0 || right_raw > Max_Set_Size || query_key < -1_000_000 || query_key > 1_000_000 do return -1
    left_length, right_length := usize(left_raw), usize(right_raw)
    if length != 4 + left_length + right_length do return -1

    left: [Max_Set_Size]i64
    right: [Max_Set_Size]i64
    result: [Max_Result_Size]i64
    left_count, right_count, result_count: usize = 0, 0, 0
    for i: usize = 0; i < left_length; i += 1 {
        value := input[4 + i]
        if value < -1_000_000 || value > 1_000_000 do return -1
        if !contains(&left[0], left_count, value) { left[left_count] = value; left_count += 1 }
    }
    for i: usize = 0; i < right_length; i += 1 {
        value := input[4 + left_length + i]
        if value < -1_000_000 || value > 1_000_000 do return -1
        if !contains(&right[0], right_count, value) { right[right_count] = value; right_count += 1 }
    }

    if operation == 0 { result[0] = bool_to_i64(contains(&left[0], left_count, query_key)); result_count = 1 }
    else if operation == 1 { result[0] = bool_to_i64(is_subset(&left[0], left_count, &right[0], right_count)); result_count = 1 }
    else if operation == 2 { result[0] = bool_to_i64(left_count < right_count && is_subset(&left[0], left_count, &right[0], right_count)); result_count = 1 }
    else if operation == 3 { result[0] = bool_to_i64(is_subset(&right[0], right_count, &left[0], left_count)); result_count = 1 }
    else if operation == 4 { result[0] = bool_to_i64(right_count < left_count && is_subset(&right[0], right_count, &left[0], left_count)); result_count = 1 }
    else if operation == 5 {
        for i: usize = 0; i < left_count; i += 1 { result[result_count] = left[i]; result_count += 1 }
        for i: usize = 0; i < right_count; i += 1 { if !contains(&left[0], left_count, right[i]) { result[result_count] = right[i]; result_count += 1 } }
    } else if operation == 6 {
        for i: usize = 0; i < left_count; i += 1 { if contains(&right[0], right_count, left[i]) { result[result_count] = left[i]; result_count += 1 } }
    } else if operation == 7 {
        for i: usize = 0; i < left_count; i += 1 { if !contains(&right[0], right_count, left[i]) { result[result_count] = left[i]; result_count += 1 } }
    } else {
        for i: usize = 0; i < left_count; i += 1 { if !contains(&right[0], right_count, left[i]) { result[result_count] = left[i]; result_count += 1 } }
        for i: usize = 0; i < right_count; i += 1 { if !contains(&left[0], left_count, right[i]) { result[result_count] = right[i]; result_count += 1 } }
    }
    for i: usize = 1; i < result_count; i += 1 {
        value := result[i]
        j := i
        for j > 0 && result[j - 1] > value { result[j] = result[j - 1]; j -= 1 }
        result[j] = value
    }
    output_bytes := result_count * 8
    if capacity < output_bytes || (output_bytes > 0 && output == nil) do return -2
    for i: usize = 0; i < result_count; i += 1 { put_i64_le(result[i], output, i * 8) }
    return i64(output_bytes)
}
