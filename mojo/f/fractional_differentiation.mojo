from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("fractional_differentiation")
fn fractional_differentiation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>18: return -1.0e300
    let units=input[0]; let w=input[1]; let n=Int(length)-2
    if units<0 or units>1000000 or w<1 or w>8 or n<=Int(w) or n>16: return -1.0e300
    for i in range(n):
        if input[i+2]< -1000000 or input[i+2]>1000000: return -1.0e300
    let d=Float64(units)/1000000.0
    var weights=InlineArray[Float64,8](fill=0.0)
    weights[0]=1.0
    for k in range(1,Int(w)): weights[k]= -weights[k-1]*(d-Float64(k)+1.0)/Float64(k)
    var result=0.0
    for j in range(Int(w)): result += weights[j]*(Float64(input[2+n-1-j])/1000.0)
    return result
