from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn fps2d_power(mut x: Int64, mut exponent: Int) -> Int64:
    var result=Int64(1)
    while exponent>0:
        if (exponent & 1)!=0: result=result*x%998244353
        x=x*x%998244353; exponent >>= 1
    return result

@export("inv_of_formal_power_series_2d")
fn inv_of_formal_power_series_2d(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length<3 or length>66: return -1
    if input[0]<1 or input[0]>8 or input[1]<1 or input[1]>8: return -1
    let n=Int(input[0]); let m=Int(input[1])
    if length!=c_size_t(2+n*m) or input[2]==0: return -1
    for i in range(n*m):
        if input[2+i]<0 or input[2+i]>=998244353: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity<c_size_t(8*n*m): return -2
    var g=InlineArray[Int64,64](fill=0)
    let inverse=fps2d_power(input[2],998244351); g[0]=inverse
    for i in range(n):
        for j in range(m):
            if i==0 and j==0: continue
            var sum=Int64(0)
            for a in range(i+1):
                for b in range(j+1):
                    if a!=0 or b!=0: sum=(sum+input[2+a*m+b]*g[(i-a)*m+j-b])%998244353
            g[i*m+j]=((998244353-sum)%998244353)*inverse%998244353
    for i in range(n*m):
        for byte in range(8): output[8*i+byte]=UInt8((g[i] >> (8*byte)) & 255)
    return Int64(8*n*m)
