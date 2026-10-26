// Clean-room bounded Kierstead-Trotter online interval coloring profile.
package online_interval_coloring

import "core:c"

MAX_N :: 64
MAX_INPUT :: 129

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

level_fits :: proc(left, right: [MAX_N]i64, levels: [MAX_N]int, last, candidate: int) -> bool {
    for anchor := 0; anchor <= last; anchor += 1 {
        point := left[anchor]
        overlap := 0
        for item := 0; item <= last; item += 1 {
            if (item == last || levels[item] <= candidate) && left[item] <= point && point <= right[item] { overlap += 1 }
        }
        if overlap > candidate do return false
    }
    return true
}

@(export)
online_interval_coloring :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > MAX_INPUT do return -1
    count := input[0]
    if count < 0 || count > MAX_N || length != c.size_t(1+2*count) do return -1
    n := int(count)
    left, right: [MAX_N]i64
    for i := 0; i < n; i += 1 {
        left[i], right[i] = input[1+2*i], input[2+2*i]
        if left[i] < -1000 || left[i] > 1000 || right[i] < -1000 || right[i] > 1000 || left[i] > right[i] do return -1
    }
    output_bytes := 8*n
    if output == nil || capacity < c.size_t(output_bytes) do return -2
    levels, local, colors: [MAX_N]int
    for i := 0; i < n; i += 1 {
        level := 1
        for !level_fits(left, right, levels, i, level) {
            level += 1
            if level > i+1 do return -1
        }
        levels[i] = level
        used: [3]bool
        for j := 0; j < i; j += 1 {
            if levels[j] == level && left[j] <= right[i] && left[i] <= right[j] && local[j] < 3 { used[local[j]] = true }
        }
        color := 0
        for color < 3 && used[color] { color += 1 }
        if color == 3 do return -1
        local[i] = color; colors[i] = 3*(level-1)+color
    }
    for i := 0; i < n; i += 1 { store_i64_le(output, 8*i, i64(colors[i])) }
    return i64(output_bytes)
}
