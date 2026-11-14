from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("discrete_logarithm_fixed_mod")
fn discrete_logarithm_fixed_mod(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>259: return -1
    if input[0]<2 or input[0]>4093 or input[1]<1 or input[1]>=input[0] or input[2]<1 or input[2]>256: return -1
    let p=Int(input[0]); let g=Int(input[1]); let n=Int(input[2])
    if length!=c_size_t(n+3): return -1
    var divisor=2
    while divisor*divisor<=p:
        if p%divisor==0: return -1
        divisor+=1
    for i in range(n):
        if input[3+i]<1 or input[3+i]>=input[0]: return -1
    var table=InlineArray[Int64,4094](fill=-1)
    var residue=1
    for exponent in range(p-1):
        if table[residue]!=-1: return -1
        table[residue]=Int64(exponent)
        residue=residue*g%p
    if residue!=1: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(8*n): return -2
    for i in range(n):
        let value=UInt64(table[Int(input[3+i])])
        for byte in range(8): output[8*i+byte]=UInt8((value >> UInt(8*byte)) & 255)
    return Int64(8*n)
