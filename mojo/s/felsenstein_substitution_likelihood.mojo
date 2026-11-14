# Independent bounded conditional-likelihood recurrence; see package rights note.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("felsenstein_substitution_likelihood")
fn felsenstein_substitution_likelihood(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 38: return -1
    let n = input[0]
    if n < 1 or n > 8: return -1
    var zero = List[Int64](capacity=8)
    var one = List[Int64](capacity=8)
    for _ in range(8):
        zero.append(0)
        one.append(0)
    var sp = 0
    var leaves = Int64(0)
    var joins = Int64(0)
    var at = 1
    while at < Int(length):
        let tag = input[at]
        at += 1
        if tag == 0:
            if at >= Int(length) or input[at] < 0 or input[at] > 1 or sp >= 8: return -1
            zero[sp] = 1-input[at]
            one[sp] = input[at]
            at += 1
            sp += 1
            leaves += 1
        elif tag == 1:
            if at+2 > Int(length) or sp < 2: return -1
            let lm = input[at]
            let rm = input[at+1]
            if lm < 0 or lm > 1 or rm < 0 or rm > 1: return -1
            at += 2
            let l0 = zero[sp-2]
            let l1 = one[sp-2]
            let r0 = zero[sp-1]
            let r1 = one[sp-1]
            var a0 = 4*l0
            var a1 = 4*l1
            var b0 = 4*r0
            var b1 = 4*r1
            if lm == 1:
                a0 = 3*l0+l1
                a1 = 3*l1+l0
            if rm == 1:
                b0 = 3*r0+r1
                b1 = 3*r1+r0
            zero[sp-2] = a0*b0
            one[sp-2] = a1*b1
            sp -= 1
            joins += 1
        else:
            return -1
    if leaves != n or joins != n-1 or sp != 1: return -1
    let shift = 29-Int(4*joins)
    let value = (zero[0]+one[0]) << shift
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for byte in range(8): output[byte] = UInt8((value >> (8*byte)) & 255)
    return 8
