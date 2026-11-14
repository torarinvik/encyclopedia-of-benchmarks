from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn smith_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[slot * 8 + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("smith_weighted_completion_time")
fn smith_weighted_completion_time(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 25:
        return -1
    let count = input[0]
    if count < 1 or count > 12 or length != c_size_t(1 + 2 * count):
        return -1
    let n = Int(count)
    var processing = InlineArray[Int64, 12](fill=0)
    var weights = InlineArray[Int64, 12](fill=0)
    var order = InlineArray[Int, 12](fill=0)
    for job in range(n):
        let p = input[1 + 2 * job]
        let w = input[2 + 2 * job]
        if p < 1 or p > 10000 or w < 1 or w > 10000:
            return -1
        processing[job] = p
        weights[job] = w
        order[job] = job
    let bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    # Stable insertion sorting keeps equal ratios in ascending job-ID order.
    for i in range(1, n):
        let job = order[i]
        var position = i
        while position > 0:
            let previous = order[position - 1]
            if weights[job] * processing[previous] <= weights[previous] * processing[job]:
                break
            order[position] = previous
            position -= 1
        order[position] = job
    var elapsed: Int64 = 0
    var total: Int64 = 0
    for i in range(n):
        let job = order[i]
        elapsed += processing[job]
        total += weights[job] * elapsed
    smith_store(output, 0, total)
    for i in range(n):
        smith_store(output, i + 1, Int64(order[i]))
    return Int64(bytes)
