from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_POINTS = 32
const MAX_DIMENSION = 4
const MAX_CENTERS = 8
const MAX_INPUT_LENGTH = 140

fn squared_distance(coordinates: view[Int64], dimension: Int,
                    row: Int, center: Int) -> Int64:
    var distance: Int64 = 0
    for axis in range(dimension):
        let difference = coordinates[row * dimension + axis] - coordinates[center * dimension + axis]
        distance += difference * difference
    return distance

fn row_is_selected(centers: view[Int64], count: Int, row: Int64) -> Bool:
    for index in range(count):
        if centers[index] == row: return True
    return False

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin],
                offset: Int, value: Int64) -> None:
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & 255)

@export("kmeans_plus_plus_seeding")
fn kmeans_plus_plus_seeding(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_INPUT_LENGTH:
        return -1
    let point_count_value = input[0]
    let dimension_value = input[1]
    let center_count_value = input[2]
    let first_row = input[3]
    if point_count_value < 1 or point_count_value > MAX_POINTS: return -1
    if dimension_value < 1 or dimension_value > MAX_DIMENSION: return -1
    if center_count_value < 1 or center_count_value > MAX_CENTERS: return -1
    if center_count_value > point_count_value: return -1
    if first_row < 0 or first_row >= point_count_value:
        return -1

    let point_count = Int(point_count_value)
    let dimension = Int(dimension_value)
    let center_count = Int(center_count_value)
    let coordinate_count = point_count * dimension
    let draw_offset = 4 + coordinate_count
    if Int(length) != draw_offset + center_count - 1: return -1

    var coordinates = InlineArray[Int64, 128](fill=0)
    for index in range(coordinate_count):
        let coordinate = input[4 + index]
        if coordinate < -16 or coordinate > 16: return -1
        coordinates[index] = coordinate

    var centers = InlineArray[Int64, 8](fill=0)
    var nearest = InlineArray[Int64, 32](fill=0)
    centers[0] = first_row
    for row in range(point_count):
        nearest[row] = squared_distance(coordinates[0:coordinate_count], dimension,
                                        row, Int(first_row))

    for step in range(center_count - 1):
        let draw = input[draw_offset + step]
        var total_weight: Int64 = 0
        for row in range(point_count): total_weight += nearest[row]
        var chosen: Int64 = -1
        if total_weight == 0:
            if draw != 0: return -1
            for row in range(point_count):
                if not row_is_selected(centers[0:step + 1], step + 1, Int64(row)):
                    chosen = Int64(row)
                    break
        else:
            if draw < 0 or draw >= total_weight: return -1
            var cumulative: Int64 = 0
            for row in range(point_count):
                cumulative += nearest[row]
                if cumulative > draw:
                    chosen = Int64(row)
                    break
        if chosen < 0: return -1
        centers[step + 1] = chosen
        for row in range(point_count):
            let distance = squared_distance(coordinates[0:coordinate_count], dimension,
                                            row, Int(chosen))
            if distance < nearest[row]: nearest[row] = distance

    let output_bytes = center_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for index in range(center_count):
        store_i64_le(output, index * 8, centers[index])
    return Int64(output_bytes)
