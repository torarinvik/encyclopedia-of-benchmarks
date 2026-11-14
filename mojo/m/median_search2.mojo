from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("median_search2")
fn median_search2(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 129:
        return -1
    if input[0] < 0 or input[0] > 128:
        return -1
    let count = Int(input[0])
    if Int(length) != count + 1:
        return -1
    for i in range(count):
        if input[i + 1] < -2147483648 or input[i + 1] > 2147483647:
            return -1
    var links = InlineArray[Int, 128](fill=-1)
    for i in range(count):
        if i + 1 < count:
            links[i] = i + 1
    var found: Int64 = 0
    var middle: Int64 = -1
    if count > 0:
        var slow = 0
        var fast = 0
        while fast >= 0 and links[fast] >= 0:
            slow = links[slow]
            fast = links[links[fast]]
        found = 1
        middle = Int64(slow)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    for byte in range(4):
        output[byte] = UInt8((found >> (8 * byte)) & 255)
        output[4 + byte] = UInt8((middle >> (8 * byte)) & 255)
    return 8
