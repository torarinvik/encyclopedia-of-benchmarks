from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_HEIGHT = 5
comptime MAX_WIDTH = 5
comptime MAX_PATHS = 3
comptime MAX_PARSEABLE_LENGTH = 11

fn single_source_paths(height: Int, width: Int, blocked: UInt64,
        source_row: Int, sink_row: Int) -> Int64:
    var ways = InlineArray[Int64, 25](fill=0)
    for row in range(height):
        for column in range(width):
            let bit = row * width + column
            let index = row * MAX_WIDTH + column
            if ((blocked >> bit) & UInt64(1)) != 0:
                ways[index] = 0
            elif row == source_row and column == 0:
                ways[index] = 1
            else:
                var from_above: Int64 = 0
                var from_left: Int64 = 0
                if row > 0:
                    from_above = ways[(row - 1) * MAX_WIDTH + column]
                if column > 0:
                    from_left = ways[row * MAX_WIDTH + column - 1]
                ways[index] = from_above + from_left
    return ways[sink_row * MAX_WIDTH + width - 1]

fn determinant(matrix: InlineArray[Int64, 9], order: Int) -> Int64:
    let permutations = InlineArray[Int, 18](
        0, 1, 2, 1, 0, 2, 0, 2, 1, 1, 2, 0, 2, 0, 1, 2, 1, 0)
    var permutation_count = 6
    if order == 1:
        permutation_count = 1
    elif order == 2:
        permutation_count = 2
    var result: Int64 = 0
    for permutation_index in range(permutation_count):
        var term: Int64 = 1
        var inversions = 0
        for row in range(order):
            let column = permutations[3 * permutation_index + row]
            term *= matrix[3 * row + column]
            for next_row in range(row + 1, order):
                if permutations[3 * permutation_index + row] > permutations[3 * permutation_index + next_row]:
                    inversions += 1
        if inversions % 2 == 0:
            result += term
        else:
            result -= term
    return result

@export("lgv_nonintersecting_paths")
fn lgv_nonintersecting_paths(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let raw_height = input[0]
    let raw_width = input[1]
    let raw_path_count = input[2]
    let raw_blocked = input[3]
    if raw_height < 1 or raw_height > MAX_HEIGHT or raw_width < 2 or raw_width > MAX_WIDTH or
        raw_path_count < 1 or raw_path_count > MAX_PATHS or raw_blocked < 0:
        return -1
    let height = Int(raw_height)
    let width = Int(raw_width)
    let path_count = Int(raw_path_count)
    if length != c_size_t(4 + 2 * path_count):
        return -1
    let cell_count = height * width
    if raw_blocked >= (Int64(1) << cell_count):
        return -1

    var source_rows = InlineArray[Int, MAX_PATHS](fill=0)
    var sink_rows = InlineArray[Int, MAX_PATHS](fill=0)
    for index in range(path_count):
        let source = input[4 + index]
        let sink = input[4 + path_count + index]
        if source < 0 or source >= raw_height or sink < 0 or sink >= raw_height or source > sink:
            return -1
        source_rows[index] = Int(source)
        sink_rows[index] = Int(sink)
        if index > 0 and (source_rows[index] <= source_rows[index - 1] or
                          sink_rows[index] <= sink_rows[index - 1]):
            return -1
        let source_bit = source_rows[index] * width
        let sink_bit = sink_rows[index] * width + width - 1
        if ((raw_blocked >> source_bit) & Int64(1)) != 0 or
            ((raw_blocked >> sink_bit) & Int64(1)) != 0:
            return -1

    var path_matrix = InlineArray[Int64, 9](fill=0)
    for source_index in range(path_count):
        for sink_index in range(path_count):
            path_matrix[source_index * 3 + sink_index] = single_source_paths(
                height, width, UInt64(raw_blocked), source_rows[source_index], sink_rows[sink_index])
    return determinant(path_matrix, path_count)
