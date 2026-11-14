from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("polynomial_discrete_antiderivative")
fn polynomial_discrete_antiderivative(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 33: return -1
    if input[0] < 1 or input[0] > 32: return -1
    let n=Int(input[0])
    if length != c_size_t(n+1): return -1
    for i in range(n):
        if input[1+i] < 0 or input[1+i] >= 998244353: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*(n+1)): return -2
    var choose=InlineArray[Int64,1089](fill=0)
    var inverse=InlineArray[Int64,33](fill=0)
    var g=InlineArray[Int64,33](fill=0)
    choose[0]=1
    for k in range(1,n+1):
        choose[33*k]=1; choose[33*k+k]=1
        for j in range(1,k): choose[33*k+j]=(choose[33*(k-1)+j-1]+choose[33*(k-1)+j])%998244353
    inverse[1]=1
    for k in range(2,n+1): inverse[k]=998244353-Int64(998244353//k)*inverse[998244353%k]%998244353
    var j=n
    while j>0:
        j-=1
        var sum=Int64(0)
        for k in range(j+2,n+1): sum=(sum+choose[33*k+j]*g[k])%998244353
        g[j+1]=((input[1+j]-sum+998244353)%998244353)*inverse[j+1]%998244353
    for i in range(n+1):
        for byte in range(8): output[8*i+byte]=UInt8((g[i] >> (8*byte)) & 255)
    return Int64(8*(n+1))
