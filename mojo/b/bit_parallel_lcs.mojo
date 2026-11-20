# Uncompiled multiword bit-parallel LCS length draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("bit_parallel_lcs")
fn bit_parallel_lcs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 515: return -1
    let nr = input[0]
    let mr = input[1]
    if nr < 0 or nr > 256 or mr < 0 or mr > 256 or length != c_size_t(2+nr+mr): return -1
    let n = Int(nr)
    let m = Int(mr)
    for i in range(2,Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    var masks = InlineArray[UInt64,1024](fill=0)
    var row = InlineArray[UInt64,4](fill=0)
    let words = (n+63)//64
    for i in range(n):
        let slot = Int(input[2+i])*4+i//64
        masks[slot] |= UInt64(1) << (i%64)
    for i in range(m):
        let symbol = Int(input[2+n+i])
        var carry = UInt64(1)
        var borrow = UInt64(0)
        for j in range(words):
            let old = row[j]
            let combined = old | masks[symbol*4+j]
            let shifted = (old << 1) | carry
            carry = old >> 63
            let first_borrow = combined < shifted
            var partial = UInt64(0)
            if first_borrow: partial = ~(shifted-combined)+1
            else: partial = combined-shifted
            let second_borrow = partial < borrow
            var difference = UInt64(0)
            if second_borrow: difference = ~UInt64(0)
            else: difference = partial-borrow
            borrow = UInt64(1) if first_borrow or second_borrow else UInt64(0)
            row[j] = combined & (combined ^ difference)
    var result = Int64(0)
    for j in range(words):
        var word = row[j]
        while word != 0:
            word &= word-1
            result += 1
    return result
