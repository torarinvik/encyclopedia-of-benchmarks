from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn determinant_rec(matrix:List[Int64],n:Int)->Int64:
    if n==1:return matrix[0]
    var result:Int64=0
    for col in range(n):
        var minor=List[Int64](capacity=(n-1)*(n-1))
        for row in range(1,n):
            for c in range(n):
                if c!=col:minor.append(matrix[row*n+c])
        let term=matrix[col]*determinant_rec(minor,n-1)
        result+=term if col%2==0 else -term
    return result
@export("determinant")
fn determinant(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>37:return -9223372036854775808
    let dv=input[0]
    if dv<1 or dv>6 or length!=c_size_t(1+dv*dv):return -9223372036854775808
    var matrix=List[Int64](capacity=36)
    for i in range(Int(dv*dv)):
        let v=input[1+i]
        if v< -9 or v>9:return -9223372036854775808
        matrix.append(v)
    return determinant_rec(matrix,Int(dv))
