from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn fc_store(output: UnsafePointer[UInt8, MutAnyOrigin], at: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[at+b] = UInt8((bits >> (8*b)) & 255)

@export("floor_and_ceiling")
fn floor_and_ceiling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 384: return -1
    let n0=input[0]; let root=input[1]; let key=input[2]
    if n0<0 or n0>127 or key< -1000000 or key>1000000 or Int(length)!=3+3*Int(n0): return -1
    if (n0==0 and root != -1) or (n0>0 and (root<0 or root>=n0)): return -1
    let none = -9223372036854775807 - 1
    var lo=none; var hi=none
    var current=Int(n0)
    if n0>0: current=Int(root)
    for _ in range(Int(n0)):
        if current>=Int(n0): break
        let base=3+3*current
        let value=input[base]; let left=input[base+1]; let right=input[base+2]
        if value< -1000000 or value>1000000 or left< -1 or right< -1 or left>=n0 or right>=n0: return -1
        if value==key: lo=value; hi=value; break
        if key<value:
            hi=value
            if left<0: current=Int(n0)
            else: current=Int(left)
        else:
            lo=value
            if right<0: current=Int(n0)
            else: current=Int(right)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16: return -2
    fc_store(output,0,lo); fc_store(output,8,hi)
    return 16
