from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn psi_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("psi_suffix_array_access")
fn psi_suffix_array_access(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 67: return -1
    let count = input[0]
    let query = input[1]
    let stride = input[2]
    if count < 1 or count > 32 or query < 0 or query >= count or stride < 1 or stride > count or length != c_size_t(3 + 2 * count): return -1
    let n = Int(count)
    var psi = InlineArray[Int, 32](fill=0)
    var sample = InlineArray[Int64, 32](fill=0)
    var destinations = InlineArray[Bool, 32](fill=False)
    var anchor = n
    for i in range(n):
        let next = input[3 + i]
        let value = input[3 + n + i]
        if next < 0 or next >= count or value < 0 or value > count: return -1
        if destinations[Int(next)]: return -1
        destinations[Int(next)] = True
        psi[i] = Int(next)
        sample[i] = value
        if value != 0 and anchor == n: anchor = i
    if anchor == n: return -1
    let anchor_value = sample[anchor]
    if (anchor_value - 1) % stride != 0: return -1
    var visited = InlineArray[Bool, 32](fill=False)
    var full = InlineArray[Int64, 32](fill=0)
    var rank = anchor
    var value = anchor_value
    for _ in range(n):
        if visited[rank]: return -1
        visited[rank] = True
        full[rank] = value
        rank = psi[rank]
        value = if value == count: 1 else: value + 1
    if rank != anchor or value != anchor_value: return -1
    for i in range(n):
        let expected = if (full[i] - 1) % stride == 0: full[i] else: 0
        if sample[i] != expected: return -1
    rank = Int(query)
    var hops: Int64 = 0
    while sample[rank] == 0:
        rank = psi[rank]
        hops += 1
        if hops >= stride: return -1
    var position = (sample[rank] - 1 - hops) % count
    if position < 0: position += count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    psi_store(output, 0, position + 1)
    psi_store(output, 1, hops)
    return 16
