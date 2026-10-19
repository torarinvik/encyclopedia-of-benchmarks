from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_ITEMS = 257
comptime BYTES_PER_TRIPLET = 12


fn sift_down(mut values: InlineArray[Int64, MAX_ITEMS], root_start: Int, end: Int):
    var root = root_start
    while root < end // 2:
        var child = root * 2 + 1
        if child + 1 < end and values[child] < values[child + 1]:
            child += 1
        if values[root] >= values[child]:
            break
        let temporary = values[root]
        values[root] = values[child]
        values[child] = temporary
        root = child


fn heap_sort(mut values: InlineArray[Int64, MAX_ITEMS], length: Int):
    var start = length // 2
    while start > 0:
        start -= 1
        sift_down(values, start, length)
    var end = length
    while end > 1:
        end -= 1
        let temporary = values[0]
        values[0] = values[end]
        values[end] = temporary
        sift_down(values, 0, end)


fn enumerate_triplets(
    values: InlineArray[Int64, MAX_ITEMS], length: Int,
    output: UnsafePointer[UInt8, MutAnyOrigin], write_output: Bool,
) -> Int:
    var result_count = 0
    for first in range(length):
        if first + 2 >= length:
            break
        if first > 0 and values[first] == values[first - 1]:
            continue
        var left = first + 1
        var right = length - 1
        while left < right:
            let sum = values[first] + values[left] + values[right]
            if sum < 0:
                left += 1
            elif sum > 0:
                right -= 1
            else:
                if write_output:
                    let byte_offset = result_count * BYTES_PER_TRIPLET
                    store_i32_le(output, byte_offset, values[first])
                    store_i32_le(output, byte_offset + 4, values[left])
                    store_i32_le(output, byte_offset + 8, values[right])
                result_count += 1
                left += 1
                right -= 1
                while left < right and values[left] == values[left - 1]:
                    left += 1
                while left < right and values[right] == values[right + 1]:
                    right -= 1
    return result_count


fn store_i32_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
):
    let bits = UInt32(Int32(value))
    for byte in range(4):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt32(255))


@export("three_sum")
fn three_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if length > c_size_t(MAX_ITEMS) or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()):
        return -1

    let item_count = Int(length)
    var values = InlineArray[Int64, MAX_ITEMS](fill=0)
    for index in range(item_count):
        let value = input[index]
        if value < -100000 or value > 100000:
            return -1
        values[index] = value

    heap_sort(values, item_count)
    let result_count = enumerate_triplets(
        values, item_count, output, False
    )
    let needed = result_count * BYTES_PER_TRIPLET
    if output_capacity < c_size_t(needed) or (
        needed != 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()
    ):
        return -2
    _ = enumerate_triplets(values, item_count, output, output != UnsafePointer[UInt8, MutAnyOrigin]())
    return Int64(result_count)
