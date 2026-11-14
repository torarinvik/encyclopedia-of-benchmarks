# Independent bounded PolyBench Nussinov recurrence; see package LICENSE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("nussinov")
fn nussinov(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let nv = input[0]
    if nv < 1 or nv > 128: return -1
    let n = Int(nv)
    var bases = List[Int](capacity=n)
    var table = List[Int64](length=n*n, fill=0)
    for i in range(n): bases.append((i+1)%4)
    for reverse_i in range(n):
        let i = n-1-reverse_i
        for j in range(i+1,n):
            var score = table[i*n+j-1]
            if i+1 < n:
                let below = table[(i+1)*n+j]
                if below > score: score = below
                var inside = table[(i+1)*n+j-1]
                if i < j-1 and bases[i]+bases[j] == 3: inside += 1
                if inside > score: score = inside
            for k in range(i+1,j):
                let split = table[i*n+k]+table[(k+1)*n+j]
                if split > score: score = split
            table[i*n+j] = score
    var checksum = Int64(0)
    for i in range(n):
        for j in range(i,n): checksum += table[i*n+j]
    return checksum
