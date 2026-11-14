from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn rrr_popcount(value: Int) -> Int:
    var count = 0
    for bit in range(8): count += (value >> bit) & 1
    return count

fn rrr_decode(cls: Int, offset: Int) -> Int:
    var remaining = offset
    for candidate in range(256):
        if rrr_popcount(candidate) == cls:
            if remaining == 0: return candidate
            remaining -= 1
    return 0

@export("rrr_class_offset_rank_select")
fn rrr_class_offset_rank_select(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 35: return -1
    let nv = input[0]
    let bv = input[1]
    let qv = input[2]
    if nv < 1 or nv > 63 or bv < 0 or qv < 0 or qv > 16: return -1
    let n = Int(nv)
    let bits = UInt64(bv)
    let q = Int(qv)
    if bits >> n != 0 or length != c_size_t(3+2*q): return -1
    for i in range(q):
        let op = input[3+2*i]
        let index = input[4+2*i]
        if (op != 0 and op != 1) or index < 1 or (op == 0 and index > nv) or (op == 1 and index > 64): return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*q): return -2
    var classes = List[Int](capacity=8)
    var offsets = List[Int](capacity=8)
    var prefix = List[Int](capacity=9)
    for _ in range(8):
        classes.append(0)
        offsets.append(0)
    for _ in range(9): prefix.append(0)
    let blocks = (n+7)//8
    for block_index in range(blocks):
        let byte_value = Int((bits >> (8*block_index)) & UInt64(255))
        classes[block_index] = rrr_popcount(byte_value)
        for candidate in range(byte_value):
            if rrr_popcount(candidate) == classes[block_index]: offsets[block_index] += 1
        prefix[block_index+1] = prefix[block_index]+classes[block_index]
    for i in range(q):
        let op = input[3+2*i]
        let index = Int(input[4+2*i])
        var answer = -1
        if op == 0:
            let block_index = (index-1)//8
            let byte_value = rrr_decode(classes[block_index], offsets[block_index])
            answer = prefix[block_index]
            for bit in range(index-8*block_index): answer += (byte_value >> bit) & 1
        else:
            var block_index = 0
            while block_index < blocks and prefix[block_index+1] < index: block_index += 1
            if block_index < blocks:
                var remaining = index-prefix[block_index]
                let byte_value = rrr_decode(classes[block_index], offsets[block_index])
                var bit = 0
                while bit < 8 and 8*block_index+bit < n:
                    if (byte_value >> bit) & 1 != 0:
                        remaining -= 1
                        if remaining == 0:
                            answer = 8*block_index+bit+1
                            break
                    bit += 1
        var encoded = bitcast[UInt64](Int64(answer))
        for byte_index in range(8):
            output[8*i+byte_index] = UInt8(encoded & UInt64(255))
            encoded = encoded >> 8
    return Int64(8*q)
