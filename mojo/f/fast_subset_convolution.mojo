# Independent ranked-transform subset convolution; see package attribution.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn population(value: Int) -> Int:
    var bits = value
    var count = 0
    while bits != 0:
        bits &= bits-1
        count += 1
    return count

@export("fast_subset_convolution")
fn fast_subset_convolution(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 33: return -1
    let nv = input[0]
    if nv < 0 or nv > 4: return -1
    let n = Int(nv)
    let size = 1 << n
    if length != c_size_t(1+2*size): return -1
    let modulus = Int64(998244353)
    for i in range(2*size):
        if input[1+i] < 0 or input[1+i] >= modulus: return -1
    let cells = (n+1)*size
    var f = List[Int64](capacity=cells)
    var g = List[Int64](capacity=cells)
    var h = List[Int64](capacity=cells)
    for _ in range(cells):
        f.append(0)
        g.append(0)
        h.append(0)
    for mask in range(size):
        let index = population(mask)*size+mask
        f[index] = input[1+mask]
        g[index] = input[1+size+mask]
    for bit in range(n):
        for mask in range(size):
            if (mask & (1 << bit)) != 0:
                let other = mask ^ (1 << bit)
                for rank in range(n+1):
                    let at = rank*size+mask
                    let prev = rank*size+other
                    f[at] = (f[at]+f[prev]) % modulus
                    g[at] = (g[at]+g[prev]) % modulus
    for mask in range(size):
        for rank in range(n+1):
            var sum = Int64(0)
            for i in range(rank+1):
                sum = (sum + f[i*size+mask]*g[(rank-i)*size+mask]) % modulus
            h[rank*size+mask] = sum
    for bit in range(n):
        for mask in range(size):
            if (mask & (1 << bit)) != 0:
                let other = mask ^ (1 << bit)
                for rank in range(n+1):
                    let at = rank*size+mask
                    h[at] = (h[at]-h[rank*size+other]+modulus) % modulus
    let required = 8*size
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    for mask in range(size):
        let value = h[population(mask)*size+mask]
        for byte in range(8): output[8*mask+byte] = UInt8((value >> (8*byte)) & 255)
    return Int64(required)
