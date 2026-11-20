package crust_opposite_pole_selection

import "core:c"

MAX_SAMPLES :: 8
MAX_CELL_VERTICES :: 8

put_i64 :: proc "contextless" (output: [^]u8, word: int, value: i64) {
    bits := u64(value)
    for b := 0; b < 8; b += 1 { output[word * 8 + b] = u8((bits >> (8 * b)) & 255) }
}

same_point :: proc "contextless" (a, b: [3]i64) -> bool {
    return a[0] == b[0] && a[1] == b[1] && a[2] == b[2]
}

@(export)
crust_opposite_pole_selection :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 1 || input_length > 226 do return -1
    n0 := input[0]
    if n0 < 1 || n0 > 8 do return -1
    n := int(n0)
    samples: [MAX_SAMPLES][3]i64
    answer: [MAX_SAMPLES][2]i64
    offset := 1
    for row := 0; row < n; row += 1 {
        if offset + 4 > int(input_length) do return -1
        sample := [3]i64{input[offset], input[offset + 1], input[offset + 2]}
        count0 := input[offset + 3]
        offset += 4
        if count0 < 1 || count0 > 8 do return -1
        for axis := 0; axis < 3; axis += 1 { if sample[axis] < -16 || sample[axis] > 16 do return -1 }
        for prev := 0; prev < row; prev += 1 { if same_point(sample, samples[prev]) do return -1 }
        samples[row] = sample
        count := int(count0)
        if offset + 3 * count > int(input_length) do return -1
        cell: [MAX_CELL_VERTICES][3]i64
        for vertex := 0; vertex < count; vertex += 1 {
            for axis := 0; axis < 3; axis += 1 {
                cell[vertex][axis] = input[offset]
                offset += 1
                if cell[vertex][axis] < -16 || cell[vertex][axis] > 16 do return -1
            }
            if same_point(cell[vertex], sample) do return -1
            for prev := 0; prev < vertex; prev += 1 { if same_point(cell[vertex], cell[prev]) do return -1 }
        }
        positive := 0
        positive_distance: i64 = -1
        for vertex := 0; vertex < count; vertex += 1 {
            distance: i64 = 0
            for axis := 0; axis < 3; axis += 1 {
                delta := cell[vertex][axis] - sample[axis]
                distance += delta * delta
            }
            if distance > positive_distance { positive_distance = distance; positive = vertex }
        }
        forward: [3]i64
        for axis := 0; axis < 3; axis += 1 { forward[axis] = cell[positive][axis] - sample[axis] }
        negative: i64 = -1
        negative_distance: i64 = -1
        for vertex := 0; vertex < count; vertex += 1 {
            distance: i64 = 0
            projection: i64 = 0
            for axis := 0; axis < 3; axis += 1 {
                delta := cell[vertex][axis] - sample[axis]
                distance += delta * delta
                projection += delta * forward[axis]
            }
            if projection < 0 && distance > negative_distance { negative_distance = distance; negative = i64(vertex) }
        }
        answer[row] = .{i64(positive), negative}
    }
    if offset != int(input_length) do return -1
    bytes := c.size_t(8 * (1 + 2 * n))
    if output == nil || output_capacity < bytes do return -2
    put_i64(output, 0, n0)
    word := 1
    for row := 0; row < n; row += 1 { put_i64(output, word, answer[row][0]); word += 1; put_i64(output, word, answer[row][1]); word += 1 }
    return i64(bytes)
}
