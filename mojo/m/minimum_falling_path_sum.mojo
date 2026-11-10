from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("minimum_falling_path_sum")
def minimum_falling_path_sum(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if input == None or length < 1:
        return -10001
    var values = input.value()
    var dimension = values[unsafe_offset=0]
    if dimension < 1 or dimension > 100:
        return -10001
    var n = Int(dimension)
    if Int(length) != 1 + n * n:
        return -10001
    for index in range(n * n):
        var value = values[unsafe_offset=1 + index]
        if value < -100 or value > 100:
            return -10001

    var costs = Array[UInt16, 102](fill=0)
    var next_costs = Array[UInt16, 100](fill=0)
    # Both buffers stay in place. Validation bounds every offset below.
    var current = costs.unsafe_ptr()
    var next_row = next_costs.unsafe_ptr()
    current[unsafe_offset=0] = 32768
    current[unsafe_offset=n + 1] = 32768
    for column in range(n):
        current[unsafe_offset=column + 1] = UInt16(values[unsafe_offset=1 + column] + 100)
    for row in range(1, n):
        for column in range(n):
            var left = current[unsafe_offset=column]
            var center = current[unsafe_offset=column + 1]
            var right = current[unsafe_offset=column + 2]
            var left_or_center = left if left < center else center
            var best = right if right < left_or_center else left_or_center
            var value = values[unsafe_offset=1 + row * n + column]
            next_row[unsafe_offset=column] = best + UInt16(value + 100)
        for column in range(n):
            current[unsafe_offset=column + 1] = next_row[unsafe_offset=column]
    var minimum = current[unsafe_offset=1]
    for column in range(1, n):
        var candidate = current[unsafe_offset=column + 1]
        if candidate < minimum:
            minimum = candidate
    return Int64(minimum) - 100 * dimension
