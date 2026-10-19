from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("egyptian_fraction")
fn egyptian_fraction(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    var numerator=input[0]; var denominator=input[1]
    if numerator < 0 or numerator > 10 or denominator < 1 or denominator > 10 or numerator > denominator: return -1
    var terms=List[Int64](capacity=10)
    while numerator != 0:
        var unit=denominator/numerator
        if denominator%numerator != 0: unit += 1
        terms.append(unit)
        numerator=numerator*unit-denominator
        denominator=denominator*unit
    let bytes=len(terms)*4
    if bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes)): return -2
    for i in range(len(terms)):
        let bits=UInt32(terms[i])
        for b in range(4): output[i*4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
