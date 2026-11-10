from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("minimum_path_cost_in_grid")
def minimum_path_cost_in_grid(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if input == None or length < 2:
        return -1
    var values = input.value()
    var row_arg = values[unsafe_offset=0]
    var column_arg = values[unsafe_offset=1]
    if row_arg < 1 or row_arg > 32 or column_arg < 1 or column_arg > 32:
        return -1
    var rows = Int(row_arg)
    var columns = Int(column_arg)
    var cells = rows * columns
    var move_offset = 2 + cells
    if Int(length) != move_offset + cells * columns:
        return -1
    for index in range(cells):
        var value = values[unsafe_offset=2 + index]
        if value < 0 or value >= Int64(cells):
            return -1
    for index in range(cells * columns):
        var cost = values[unsafe_offset=move_offset + index]
        if cost < 1 or cost > 100:
            return -1

    var costs = Array[UInt32, 32](fill=0)
    var next_costs = Array[UInt32, 32](fill=0)
    # Both buffers stay in place and every column index is below the validated limit.
    var current = costs.unsafe_ptr()
    var next_row = next_costs.unsafe_ptr()
    for row in range(rows - 1):
        for target in range(columns):
            next_row[unsafe_offset=target] = 65536
        for column in range(columns):
            var value = Int(values[unsafe_offset=2 + row * columns + column])
            var base = current[unsafe_offset=column] + UInt32(value)
            for target in range(columns):
                var move_cost = values[unsafe_offset=move_offset + value * columns + target]
                var candidate = base + UInt32(move_cost)
                var previous = next_row[unsafe_offset=target]
                next_row[unsafe_offset=target] = candidate if candidate < previous else previous
        for column in range(columns):
            current[unsafe_offset=column] = next_row[unsafe_offset=column]

    var minimum = UInt32(65536)
    var last_row = 2 + (rows - 1) * columns
    for column in range(columns):
        var candidate = current[unsafe_offset=column] + UInt32(values[unsafe_offset=last_row + column])
        if candidate < minimum:
            minimum = candidate
    return Int64(minimum)
