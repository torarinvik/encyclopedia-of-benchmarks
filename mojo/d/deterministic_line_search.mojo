# Independent deterministic doubling search; see package attribution.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("deterministic_line_search")
fn deterministic_line_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let target = input[0]
    if target == 0 or target < -50000 or target > 50000: return -1
    var distance = target
    if distance < 0: distance = -distance
    var traveled = Int64(0)
    var leg = Int64(0)
    var reach = Int64(1)
    while True:
        if ((leg & 1) == 0) == (target < 0) and distance <= reach:
            traveled += distance
            break
        traveled += 2 * reach
        reach *= 2
        leg += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    for byte in range(8):
        output[byte] = UInt8((traveled >> (8*byte)) & 255)
        output[8+byte] = UInt8((leg >> (8*byte)) & 255)
    return 16
