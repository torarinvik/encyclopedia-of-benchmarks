from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("beebs_lcdnum")
fn beebs_lcdnum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 5: return -1
    for i in range(5):
        if input[i] < 0 or input[i] > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 5: return -2
    var masks = List[UInt8](capacity=16)
    masks.append(0x00); masks.append(0x24); masks.append(0x5d); masks.append(0x6d)
    masks.append(0x2e); masks.append(0x5d); masks.append(0x7b); masks.append(0x25)
    masks.append(0x7f); masks.append(0x6f); masks.append(0x3f); masks.append(0x7a)
    masks.append(0x53); masks.append(0x7c); masks.append(0x5b); masks.append(0x1b)
    for i in range(5): output[i] = masks[Int(input[i] & 15)]
    return 5
