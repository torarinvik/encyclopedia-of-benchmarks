from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("fannkuch")
fn fannkuch(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 8: return -1
    let n = Int(n0)
    var perm = List[Int](length=n, fill=0)
    var current = List[Int](length=n, fill=0)
    var count = List[Int](length=n, fill=0)
    for i in range(n): current[i] = i
    var r = n
    var maximum: Int64 = 0
    while True:
        while r != 1:
            count[r - 1] = r
            r -= 1
        if current[0] != 0 and current[n - 1] != n - 1:
            for i in range(1, n): perm[i] = current[i]
            var k = current[0]
            var flips: Int64 = 0
            while True:
                var left = 1
                var right = k - 1
                while left < right:
                    let temporary = perm[left]
                    perm[left] = perm[right]
                    perm[right] = temporary
                    left += 1
                    right -= 1
                flips += 1
                let next = perm[k]
                perm[k] = k
                k = next
                if k == 0: break
            if flips > maximum: maximum = flips
        while True:
            if r == n: return maximum
            let first = current[0]
            for i in range(r): current[i] = current[i + 1]
            current[r] = first
            count[r] -= 1
            if count[r] > 0: break
            r += 1
