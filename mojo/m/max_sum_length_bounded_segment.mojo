from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn segment_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("max_sum_length_bounded_segment")
fn max_sum_length_bounded_segment(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
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
    var prefix = InlineArray[Int64, 33](fill=0)
    for i in range(n):
        let value = input[3 + i]
        if value < -10000 or value > 10000:
            return -1
        prefix[i + 1] = prefix[i] + value
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24:
        return -2

    var candidates = InlineArray[Int, 33](fill=0)
    var head = 0
    var tail = 0
    var best_sum: Int64 = 0
    var best_start = 0
    var best_end = 0
    var found = False
    for end in range(lower, n + 1):
        let added = end - lower
        while tail > head and prefix[candidates[tail - 1]] > prefix[added]:
            tail -= 1
        candidates[tail] = added
        tail += 1
        let earliest = if end > upper: end - upper else: 0
        while head < tail and candidates[head] < earliest:
            head += 1
        let start = candidates[head]
        let total = prefix[end] - prefix[start]
        if not found or total > best_sum or (total == best_sum and (start < best_start or (start == best_start and end < best_end))):
            found = True
            best_sum = total
            best_start = start
            best_end = end
    segment_store(output, 0, best_sum)
    segment_store(output, 1, Int64(best_start))
    segment_store(output, 2, Int64(best_end))
    return 24
