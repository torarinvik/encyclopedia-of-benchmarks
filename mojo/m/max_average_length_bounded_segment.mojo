from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn average_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("max_average_length_bounded_segment")
fn max_average_length_bounded_segment(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 35:
        return -1
    let count = input[0]
    let lower_bound = input[1]
    let upper_bound = input[2]
    if count < 1 or count > 32 or lower_bound < 1 or upper_bound < lower_bound or upper_bound > count or length != c_size_t(3 + count):
        return -1
    let n = Int(count)
    let lower = Int(lower_bound)
    let upper = Int(upper_bound)
    var values = InlineArray[Int64, 32](fill=0)
    for i in range(n):
        let value = input[3 + i]
        if value < -10000 or value > 10000:
            return -1
        values[i] = value
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 32:
        return -2
    var best_sum: Int64 = 0
    var best_length = 1
    var best_start = 0
    var best_end = 0
    var found = False
    for start in range(n):
        var sum: Int64 = 0
        let limit = min(n, start + upper)
        for end in range(start + 1, limit + 1):
            sum += values[end - 1]
            let size = end - start
            if size < lower:
                continue
            let left = sum * Int64(best_length)
            let right = best_sum * Int64(size)
            let earlier = size < best_length or (size == best_length and (start < best_start or (start == best_start and end < best_end)))
            if not found or left > right or (left == right and earlier):
                found = True
                best_sum = sum
                best_length = size
                best_start = start
                best_end = end
    average_store(output, 0, best_sum)
    average_store(output, 1, Int64(best_length))
    average_store(output, 2, Int64(best_start))
    average_store(output, 3, Int64(best_end))
    return 32
