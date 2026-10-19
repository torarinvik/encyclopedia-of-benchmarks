from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("base85")
fn base85(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 66: return -1
    let mode = input[0]
    if mode != 0 and mode != 1: return -1
    let n = Int(length) - 1
    var out = List[UInt8](capacity=128)
    if mode == 0:
        for start in range(0, n, 4):
            let block = min(4, n - start)
            var value: UInt64 = 0
            for j in range(4):
                var byte: Int64 = 0
                if j < block:
                    byte = input[start + j + 1]
                    if byte < 0 or byte > 255: return -1
                value = (value << 8) | UInt64(byte)
            var digits = List[Int](capacity=5)
            for _ in range(5):
                digits.append(Int(value % 85))
                value /= 85
            let emitted = 5 if block == 4 else block + 1
            for j in range(emitted):
                out.append(UInt8(33 + digits[4 - j]))
    else:
        var start = 0
        while start < n:
            let group = min(5, n - start)
            if group == 1: return -1
            var value: UInt64 = 0
            for j in range(group):
                let ch = input[start + j + 1]
                if ch < 33 or ch > 117: return -1
                value = value * 85 + UInt64(ch - 33)
            if group < 5:
                for _ in range(5 - group): value = value * 85 + 84
            if value > 4294967295: return -1
            let byte_count = 4 if group == 5 else group - 1
            for j in range(byte_count):
                let shift = 24 - 8 * j
                out.append(UInt8((value >> shift) & 255))
            start += group
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(out)): return -2
    for i in range(len(out)): output[i] = out[i]
    return Int64(len(out))
