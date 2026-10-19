from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("floyd_triangle")
fn floyd_triangle(rows: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if rows<0 or rows>90: return -1
    let bytes=Int(rows*(rows+1))
    if capacity<c_size_t(bytes) or (bytes>0 and output==UnsafePointer[UInt8,MutAnyOrigin]()): return -2
    var number: UInt32=1
    var at=0
    for row in range(1,Int(rows)+1):
        for _ in range(row):
            output[at]=UInt8(number&255); output[at+1]=UInt8((number>>8)&255)
            at+=2; number+=1
    return Int64(bytes)
