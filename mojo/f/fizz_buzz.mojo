from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
from std.collections import List
from std.collections import InlineArray

fn fizz_append_number(mut out: List[UInt8], value: Int64):
    var digits = InlineArray[UInt8, 3](fill=0)
    var nd = 0
    var x = value
    while x > 0:
        digits[nd] = UInt8(48 + x % 10); nd += 1; x /= 10
    while nd > 0:
        nd -= 1; out.append(digits[nd])

@export("fizz_buzz")
fn fizz_buzz(n: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if n < 1 or n > 512: return -1
    var staged = List[UInt8](capacity=2364)
    for i in range(1, Int(n) + 1):
        if i % 15 == 0:
            staged.append(UInt8(70)); staged.append(UInt8(105)); staged.append(UInt8(122)); staged.append(UInt8(122))
            staged.append(UInt8(66)); staged.append(UInt8(117)); staged.append(UInt8(122)); staged.append(UInt8(122))
        elif i % 3 == 0:
            staged.append(UInt8(70)); staged.append(UInt8(105)); staged.append(UInt8(122)); staged.append(UInt8(122))
        elif i % 5 == 0:
            staged.append(UInt8(66)); staged.append(UInt8(117)); staged.append(UInt8(122)); staged.append(UInt8(122))
        else: fizz_append_number(staged, Int64(i))
        staged.append(UInt8(32))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
