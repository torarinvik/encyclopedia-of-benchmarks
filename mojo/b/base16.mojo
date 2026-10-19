from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn append_hex(mut out: List[UInt8], value: Int):
    let alphabet = "0123456789ABCDEF"
    out.append(UInt8(alphabet[value]))

@export("base16")
fn base16(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
         output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let mode = input[0]
    if mode != 0 and mode != 1: return -1
    let n = Int(length) - 1
    var staged = List[UInt8](capacity=128)
    if mode == 0:
        for i in range(n):
            let value = input[i + 1]
            if value < 0 or value > 255: return -1
            append_hex(staged, Int(value / 16))
            append_hex(staged, Int(value % 16))
    else:
        if n % 2 != 0: return -1
        for i in range(0, n, 2):
            var pair: Int = 0
            for j in range(2):
                let ch = input[i + 1 + j]
                var digit: Int64 = -1
                if ch >= 48 and ch <= 57: digit = ch - 48
                elif ch >= 65 and ch <= 70: digit = ch - 55
                if digit < 0: return -1
                pair = pair * 16 + Int(digit)
            staged.append(UInt8(pair))
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(staged)): return -2
    for i in range(len(staged)): output[i] = staged[i]
    return Int64(len(staged))
