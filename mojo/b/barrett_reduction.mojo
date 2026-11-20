from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_MODULUS = 65535
const MAX_VALUES = 12
const MAX_LENGTH = 15
const RADIX: Int64 = 4294967296

@export("barrett_reduction")
fn barrett_reduction(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>MAX_LENGTH: return -1
    if input[0]<2 or input[0]>MAX_MODULUS or input[1]<0 or input[1]>MAX_VALUES: return -1
    let modulus=Int64(input[0])
    let count=Int(input[1])
    if length!=c_size_t(2+count): return -1
    let square_bound=modulus*modulus
    for i in range(count):
        if input[2+i]<0 or input[2+i]>=square_bound: return -1

    let reciprocal=RADIX/modulus
    var checksum:Int64=0
    for i in range(count):
        let value=input[2+i]
        let quotient=(value*reciprocal)/RADIX
        var remainder=value-quotient*modulus
        if remainder>=modulus: remainder=remainder-modulus
        checksum=checksum+Int64(i+1)*(remainder+1)
    return checksum
