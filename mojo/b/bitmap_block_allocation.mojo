from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("bitmap_block_allocation")
fn bitmap_block_allocation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 66: return -1
    let bv = input[0]
    let ov = input[1]
    if bv < 1 or bv > 4096 or ov < 0 or ov > 32: return -1
    let bit_count = Int(bv)
    let operations = Int(ov)
    if length != c_size_t(2+2*operations): return -1
    for i in range(operations):
        let offset = input[2+2*i]
        let count = input[3+2*i]
        if offset < 0 or offset > bv or count < 0 or count > bv-offset: return -1
    let byte_count = (bit_count+7)//8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    var bitmap = List[UInt8](capacity=512)
    for _ in range(byte_count): bitmap.append(UInt8(0))
    for i in range(bit_count):
        if i%2 == 0: bitmap[i//8] |= UInt8(1 << (i%8))
    for i in range(operations):
        let offset = Int(input[2+2*i])
        let count = Int(input[3+2*i])
        for bit in range(offset, offset+count):
            let mask = UInt8(1 << (bit%8))
            let byte = bit//8
            if i%3 == 0: bitmap[byte] |= mask
            elif i%3 == 1: bitmap[byte] &= mask ^ UInt8(255)
            else: bitmap[byte] ^= mask
    for byte in range(byte_count): output[byte] = bitmap[byte]
    return Int64(byte_count)
