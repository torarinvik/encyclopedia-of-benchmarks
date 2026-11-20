"""Bounded Crust pole selection over supplied Voronoi-cell vertices."""
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_SAMPLES = 8
comptime MAX_CELL_VERTICES = 8

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[word * 8 + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("crust_opposite_pole_selection")
fn crust_opposite_pole_selection(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 226: return -1
    let n_value = input[0]
    if n_value < 1 or n_value > 8: return -1
    let n = Int(n_value)
    var samples = InlineArray[Int64, MAX_SAMPLES * 3](fill=0)
    var answer = InlineArray[Int64, MAX_SAMPLES * 2](fill=0)
    var offset = 1
    for row in range(n):
        if offset + 4 > Int(length): return -1
        var sample = InlineArray[Int64, 3](fill=0)
        for axis in range(3): sample[axis] = input[offset + axis]
        let count_value = input[offset + 3]
        offset += 4
        if count_value < 1 or count_value > 8: return -1
        let count = Int(count_value)
        for axis in range(3):
            if sample[axis] < -16 or sample[axis] > 16: return -1
        for previous in range(row):
            if samples[previous * 3] == sample[0] and samples[previous * 3 + 1] == sample[1] and samples[previous * 3 + 2] == sample[2]: return -1
        for axis in range(3): samples[row * 3 + axis] = sample[axis]
        if offset + 3 * count > Int(length): return -1

        var cell = InlineArray[Int64, MAX_CELL_VERTICES * 3](fill=0)
        for vertex in range(count):
            for axis in range(3):
                let coordinate = input[offset]
                offset += 1
                if coordinate < -16 or coordinate > 16: return -1
                cell[vertex * 3 + axis] = coordinate
            if cell[vertex * 3] == sample[0] and cell[vertex * 3 + 1] == sample[1] and cell[vertex * 3 + 2] == sample[2]: return -1
            for previous in range(vertex):
                if cell[vertex * 3] == cell[previous * 3] and cell[vertex * 3 + 1] == cell[previous * 3 + 1] and cell[vertex * 3 + 2] == cell[previous * 3 + 2]: return -1

        var positive = 0
        var positive_distance = Int64(-1)
        for vertex in range(count):
            var distance = Int64(0)
            for axis in range(3):
                let delta = cell[vertex * 3 + axis] - sample[axis]
                distance += delta * delta
            if distance > positive_distance:
                positive_distance = distance
                positive = vertex
        var forward = InlineArray[Int64, 3](fill=0)
        for axis in range(3): forward[axis] = cell[positive * 3 + axis] - sample[axis]
        var negative = Int64(-1)
        var negative_distance = Int64(-1)
        for vertex in range(count):
            var distance = Int64(0)
            var projection = Int64(0)
            for axis in range(3):
                let delta = cell[vertex * 3 + axis] - sample[axis]
                distance += delta * delta
                projection += delta * forward[axis]
            if projection < 0 and distance > negative_distance:
                negative_distance = distance
                negative = Int64(vertex)
        answer[row * 2] = Int64(positive)
        answer[row * 2 + 1] = negative

    if offset != Int(length): return -1
    let output_bytes = 8 * (1 + 2 * n)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    store_i64_le(output, 0, n_value)
    for row in range(n):
        store_i64_le(output, 1 + 2 * row, answer[row * 2])
        store_i64_le(output, 2 + 2 * row, answer[row * 2 + 1])
    return Int64(output_bytes)
