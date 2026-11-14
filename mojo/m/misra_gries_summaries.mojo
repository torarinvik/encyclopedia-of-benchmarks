from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn misra_gries_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("misra_gries_summaries")
fn misra_gries_summaries(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66:
        return -1
    let limit = input[0]
    let count = input[1]
    if limit < 1 or limit > 8 or count < 0 or count > 64 or length != c_size_t(count + 2):
        return -1
    var counts = InlineArray[Int64, 16](fill=0)
    var used: Int64 = 0
    for i in range(Int(count)):
        let item = input[2 + i]
        if item < 0 or item > 15:
            return -1
        let index = Int(item)
        if counts[index] > 0:
            counts[index] += 1
        elif used < limit:
            counts[index] = 1
            used += 1
        else:
            for candidate in range(16):
                if counts[candidate] > 0:
                    counts[candidate] -= 1
                    if counts[candidate] == 0:
                        used -= 1
    let bytes = 8 * (1 + 2 * Int(used))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    misra_gries_store(output, 0, used)
    var slot = 1
    for item in range(16):
        if counts[item] > 0:
            misra_gries_store(output, slot, Int64(item))
            misra_gries_store(output, slot + 1, counts[item])
            slot += 2
    return Int64(bytes)
