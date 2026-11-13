from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(998244353)

@export("deque_operate_all_composite")
fn deque_operate_all_composite(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 193: return -1
    if values[0] < 0 or values[0] > 64: return -1
    let count = Int(values[0])
    var a = InlineArray[Int64, 256](fill=1)
    var b = InlineArray[Int64, 256](fill=0)
    var head = 64
    var tail = 64
    var pos = 1
    var checksum: Int64 = 0
    var query: Int64 = 0
    for _ in range(count):
        if c_size_t(pos) >= length: return -1
        let op = values[pos]
        pos += 1
        var leaf = -1
        var new_a: Int64 = 1
        var new_b: Int64 = 0
        if op == 0 or op == 1:
            if c_size_t(pos + 2) > length: return -1
            new_a = values[pos]
            new_b = values[pos + 1]
            pos += 2
            if new_a < 1 or new_a >= MODULUS or new_b < 0 or new_b >= MODULUS: return -1
            if op == 0:
                if head == 0: return -1
                head -= 1
                leaf = head
            else:
                if tail == 128: return -1
                leaf = tail
                tail += 1
        elif op == 2 or op == 3:
            if head == tail: return -1
            if op == 2:
                leaf = head
                head += 1
            else:
                tail -= 1
                leaf = tail
        elif op == 4:
            if c_size_t(pos) >= length: return -1
            let x = values[pos]
            pos += 1
            if x < 0 or x >= MODULUS: return -1
            let answer = (a[1] * x + b[1]) % MODULUS
            query += 1
            checksum += query * (answer + 1)
        else:
            return -1
        if leaf >= 0:
            var node = 128 + leaf
            a[node] = new_a
            b[node] = new_b
            while node > 1:
                node //= 2
                a[node] = a[2 * node + 1] * a[2 * node] % MODULUS
                b[node] = (a[2 * node + 1] * b[2 * node] + b[2 * node + 1]) % MODULUS
    if c_size_t(pos) != length: return -1
    return checksum
