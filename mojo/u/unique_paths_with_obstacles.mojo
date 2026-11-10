from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("unique_paths_with_obstacles")
def unique_paths_with_obstacles(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if input == None or length < 2:
        return -1
    var values = input.value()
    var rows = values[unsafe_offset=0]
    var columns = values[unsafe_offset=1]
    if rows < 1 or rows > 20 or columns < 1 or columns > 20:
        return -1
    if length != c_size_t(2 + rows * columns):
        return -1

    var paths = Array[UInt64, 20](fill=0)
    var previous_row = paths.unsafe_ptr()
    previous_row[unsafe_offset=0] = 1
    var cells_seen: UInt64 = 0
    var left: UInt64 = 0
    var index = 2
    while index < Int(length):
        left = 0
        for column in range(Int(columns)):
            var obstacle = UInt64(values[unsafe_offset=index])
            cells_seen |= obstacle
            left = left + previous_row[unsafe_offset=column] if obstacle == 0 else 0
            previous_row[unsafe_offset=column] = left
            index += 1
    if cells_seen > 1:
        return -1
    return Int64(left)
