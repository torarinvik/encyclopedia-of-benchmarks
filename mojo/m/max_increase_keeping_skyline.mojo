from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin


@export("max_increase_keeping_skyline")
def max_increase_keeping_skyline(
    input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t
) abi("C") -> Int64:
    if input == None or length < 2 or length > 2501:
        return -1
    var values = input.value()
    var n = values[unsafe_offset=0]
    if n < 2 or n > 50 or length != c_size_t(1 + n * n):
        return -1
    var size = Int(n)
    var rows = Array[UInt8, 50](fill=0)
    var columns = Array[UInt8, 50](fill=0)
    var row_max = rows.unsafe_ptr()
    var column_max = columns.unsafe_ptr()
    var tallest: UInt64 = 0
    var height_sum: UInt32 = 0
    for row in range(size):
        var row_tallest: UInt8 = 0
        var start = 1 + row * size
        for column in range(size):
            var value = UInt64(values[unsafe_offset=start + column])
            tallest = max(tallest, value)
            height_sum += UInt32(value)
            var height = UInt8(value)
            row_tallest = max(row_tallest, height)
            column_max[unsafe_offset=column] = max(column_max[unsafe_offset=column], height)
        row_max[unsafe_offset=row] = row_tallest
    if tallest > 100:
        return -1

    var skyline_sum: UInt32 = 0
    if size <= 10:
        for row in range(size):
            for column in range(size):
                skyline_sum += UInt32(min(row_max[unsafe_offset=row], column_max[unsafe_offset=column]))
    else:
        var row_histogram = Array[UInt8, 101](fill=0)
        var column_histogram = Array[UInt8, 101](fill=0)
        var row_counts = row_histogram.unsafe_ptr()
        var column_counts = column_histogram.unsafe_ptr()
        var lowest = 100
        for index in range(size):
            lowest = min(lowest, min(Int(row_max[unsafe_offset=index]), Int(column_max[unsafe_offset=index])))
            row_counts[unsafe_offset=Int(row_max[unsafe_offset=index])] += 1
            column_counts[unsafe_offset=Int(column_max[unsafe_offset=index])] += 1
        var rows_above = UInt32(size)
        var columns_above = UInt32(size)
        skyline_sum = rows_above * columns_above * UInt32(lowest)
        for height in range(lowest, Int(tallest)):
            rows_above -= UInt32(row_counts[unsafe_offset=height])
            columns_above -= UInt32(column_counts[unsafe_offset=height])
            skyline_sum += rows_above * columns_above
    return Int64(skyline_sum - height_sum)
