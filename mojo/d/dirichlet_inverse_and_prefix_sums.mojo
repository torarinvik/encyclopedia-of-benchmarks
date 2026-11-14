from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dips_power(mut base: Int64, mut exponent: Int) -> Int64:
    var result = Int64(1)
    while exponent > 0:
        if (exponent & 1) != 0: result = result*base%998244353
        base = base*base%998244353
        exponent >>= 1
    return result

fn dips_find(q: InlineArray[Int, 15], count: Int, value: Int) -> Int:
    var lo = 0; var hi = count
    while lo < hi:
        let mid = lo+(hi-lo)//2
        if q[mid] < value: lo = mid+1
        else: hi = mid
    if lo < count and q[lo] == value: return lo
    return -1

@export("dirichlet_inverse_and_prefix_sums")
fn dirichlet_inverse_and_prefix_sums(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 16: return -1
    if input[0] < 1 or input[0] > 64: return -1
    let n = Int(input[0])
    var q = InlineArray[Int, 15](fill=0)
    var count = 0; var i = n
    while i > 0:
        let value = n//i
        if count == 0 or q[count-1] != value:
            q[count] = value; count += 1
        i -= 1
    if length != c_size_t(1+count) or input[1] == 0: return -1
    for j in range(count):
        if input[1+j] < 0 or input[1+j] >= 998244353: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*count): return -2
    let inverse = dips_power(input[1],998244351)
    var g = InlineArray[Int64, 15](fill=0)
    for j in range(count):
        let x = q[j]
        var left = 2; var total = Int64(0)
        while left <= x:
            let quotient = x//left; let right = x//quotient
            let hi = dips_find(q,count,right); let lo = dips_find(q,count,left-1)
            let gi = dips_find(q,count,quotient)
            if hi < 0 or lo < 0 or gi < 0: return -1
            let interval = (input[1+hi]-input[1+lo]+998244353)%998244353
            total = (total+interval*g[gi])%998244353
            left = right+1
        g[j] = ((1-total+998244353)%998244353)*inverse%998244353
    for j in range(count):
        for byte in range(8): output[8*j+byte] = UInt8((g[j] >> (8*byte)) & 255)
    return Int64(8*count)
