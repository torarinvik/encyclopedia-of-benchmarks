from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(998244353)

@export("point_set_range_composite")
fn point_set_range_composite(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 162: return -1
    let n64 = values[0]
    let q64 = values[1]
    if n64 < 1 or n64 > 16 or q64 < 0 or q64 > 32: return -1
    let n = Int(n64)
    let q = Int(q64)
    if length != c_size_t(2 + 2 * n + 4 * q): return -1
    var a = InlineArray[Int64, 64](fill=1)
    var b = InlineArray[Int64, 64](fill=0)
    var base = 1
    while base < n: base *= 2
    for i in range(n):
        let x = values[2 + 2 * i]
        let y = values[3 + 2 * i]
        if x < 0 or x >= MODULUS or y < 0 or y >= MODULUS: return -1
        a[base + i] = x
        b[base + i] = y
    var node = base - 1
    while node > 0:
        a[node] = a[2 * node + 1] * a[2 * node] % MODULUS
        b[node] = (a[2 * node + 1] * b[2 * node] + b[2 * node + 1]) % MODULUS
        node -= 1
    var checksum: Int64 = 0
    var query_number: Int64 = 0
    for operation in range(q):
        let cursor = 2 + 2 * n + 4 * operation
        let opcode = values[cursor]
        let first = values[cursor + 1]
        let second = values[cursor + 2]
        let third = values[cursor + 3]
        if opcode == 0:
            if first < 0 or first >= n64 or second < 0 or second >= MODULUS or third < 0 or third >= MODULUS: return -1
            node = base + Int(first)
            a[node] = second
            b[node] = third
            while node > 1:
                node //= 2
                a[node] = a[2 * node + 1] * a[2 * node] % MODULUS
                b[node] = (a[2 * node + 1] * b[2 * node] + b[2 * node + 1]) % MODULUS
        elif opcode == 1:
            if first < 0 or first > second or second > n64 or third < 0 or third >= MODULUS: return -1
            var left = base + Int(first)
            var right = base + Int(second)
            var la: Int64 = 1
            var lb: Int64 = 0
            var ra: Int64 = 1
            var rb: Int64 = 0
            while left < right:
                if left % 2 == 1:
                    lb = (a[left] * lb + b[left]) % MODULUS
                    la = a[left] * la % MODULUS
                    left += 1
                if right % 2 == 1:
                    right -= 1
                    rb = (ra * b[right] + rb) % MODULUS
                    ra = ra * a[right] % MODULUS
                left //= 2
                right //= 2
            let answer = (ra * ((la * third + lb) % MODULUS) + rb) % MODULUS
            query_number += 1
            checksum = (checksum + query_number * answer) % MODULUS
        else:
            return -1
    return checksum
