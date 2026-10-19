from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List
from std.collections import InlineArray

@export("first_n_fibonacci")
fn first_n_fibonacci(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let count = input[0]
    if count < 3 or count > 79: return -1
    var staged = List[UInt8](capacity=736)
    var prev: Int64 = 0
    var curr: Int64 = 1
    for i in range(Int(count)):
        var value: Int64 = 0
        if i == 1: value = 1
        elif i >= 2:
            value = prev + curr
            prev = curr
            curr = value
        var digits = InlineArray[UInt8, 20](fill=0)
        var nd = 0
        var rest = value
        if rest == 0:
            digits[0] = UInt8(48); nd = 1
        else:
            while rest > 0:
                digits[nd] = UInt8(48 + rest % 10); nd += 1; rest /= 10
        while nd > 0:
            nd -= 1; staged.append(digits[nd])
        staged.append(UInt8(0))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
