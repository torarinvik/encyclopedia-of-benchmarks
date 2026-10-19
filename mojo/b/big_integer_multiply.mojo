from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("big_integer_multiply")
fn big_integer_multiply(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 66: return -1
    let la = input[0]; let lb = input[1]
    if la < 1 or la > 32 or lb < 1 or lb > 32 or length != c_size_t(2 + la + lb): return -1
    let a_len = Int(la); let b_len = Int(lb)
    for i in range(a_len):
        let d = input[2 + i]
        if d < 48 or d > 57 or (i == 0 and a_len > 1 and d == 48): return -1
    for i in range(b_len):
        let d = input[2 + a_len + i]
        if d < 48 or d > 57 or (i == 0 and b_len > 1 and d == 48): return -1
    var product = List[Int](capacity=64)
    for _ in range(64): product.append(0)
    let zero = (a_len == 1 and input[2] == 48) or (b_len == 1 and input[2 + a_len] == 48)
    if not zero:
        for i in range(a_len):
            for j in range(b_len):
                let pos = i + j
                let mul = Int((input[2 + a_len - 1 - i] - 48) * (input[2 + a_len + b_len - 1 - j] - 48))
                product[pos + 1] += (product[pos] + mul) // 10
                product[pos] = (product[pos] + mul) % 10
    var size = a_len + b_len
    if zero: size = 1
    elif product[size - 1] == 0: size -= 1
    var result = List[UInt8](capacity=size)
    for i in range(size): result.append(UInt8(48) if zero else UInt8(48 + product[size - 1 - i]))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(size): return -2
    for i in range(size): output[i] = result[i]
    return Int64(size)
