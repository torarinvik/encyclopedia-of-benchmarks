from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INTERVALS = 256


fn write_i32_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
):
    let bits = UInt32(Int32(value))
    for byte in range(4):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt32(255))


@export("merge_intervals")
fn merge_intervals(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 514:
        return -1

    let word_count = Int(length)
    let interval_count = input[0]
    if interval_count < 0 or interval_count > MAX_INTERVALS:
        return -1
    if word_count != 1 + 2 * Int(interval_count):
        return -1

    var intervals = InlineArray[Int64, MAX_INTERVALS * 2](fill=0)
    for index in range(Int(interval_count)):
        let start = input[1 + index * 2]
        let end = input[2 + index * 2]
        if (
            start < -2147483648 or start > 2147483647
            or end < -2147483648 or end > 2147483647
            or start > end
        ):
            return -1
        intervals[index * 2] = start
        intervals[index * 2 + 1] = end

    # Sort the private pair array by start, preserving the source's sort-and-merge flow.
    for index in range(1, Int(interval_count)):
        let key_start = intervals[index * 2]
        let key_end = intervals[index * 2 + 1]
        var position = index
        while position > 0 and intervals[(position - 1) * 2] > key_start:
            intervals[position * 2] = intervals[(position - 1) * 2]
            intervals[position * 2 + 1] = intervals[(position - 1) * 2 + 1]
            position -= 1
        intervals[position * 2] = key_start
        intervals[position * 2 + 1] = key_end

    var merged_count = 0
    for index in range(Int(interval_count)):
        let start = intervals[index * 2]
        let end = intervals[index * 2 + 1]
        if merged_count > 0 and start <= intervals[(merged_count - 1) * 2 + 1]:
            if end > intervals[(merged_count - 1) * 2 + 1]:
                intervals[(merged_count - 1) * 2 + 1] = end
        else:
            intervals[merged_count * 2] = start
            intervals[merged_count * 2 + 1] = end
            merged_count += 1

    let byte_count = merged_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(byte_count):
        return -2
    for index in range(merged_count):
        write_i32_le(output, index * 8, intervals[index * 2])
        write_i32_le(output, index * 8 + 4, intervals[index * 2 + 1])
    return Int64(byte_count)
