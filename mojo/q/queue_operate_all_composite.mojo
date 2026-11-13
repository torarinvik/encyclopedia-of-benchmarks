from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(998244353)

@export("queue_operate_all_composite")
fn queue_operate_all_composite(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 193: return -1
    if values[0] < 0 or values[0] > 64: return -1
    let count = Int(values[0])
    var back_a = InlineArray[Int64, 64](fill=0)
    var back_b = InlineArray[Int64, 64](fill=0)
    var agg_a = InlineArray[Int64, 64](fill=0)
    var agg_b = InlineArray[Int64, 64](fill=0)
    var front_a = InlineArray[Int64, 64](fill=0)
    var front_b = InlineArray[Int64, 64](fill=0)
    var back_size = 0
    var front_size = 0
    var pos = 1
    var checksum: Int64 = 0
    var query: Int64 = 0
    for _ in range(count):
        if c_size_t(pos) >= length: return -1
        let op = values[pos]
        pos += 1
        if op == 0:
            if c_size_t(pos + 2) > length: return -1
            let a = values[pos]
            let b = values[pos + 1]
            pos += 2
            if a < 1 or a >= MODULUS or b < 0 or b >= MODULUS: return -1
            back_a[back_size] = a
            back_b[back_size] = b
            if back_size == 0:
                agg_a[back_size] = a
                agg_b[back_size] = b
            else:
                agg_a[back_size] = a * agg_a[back_size - 1] % MODULUS
                agg_b[back_size] = (a * agg_b[back_size - 1] + b) % MODULUS
            back_size += 1
        elif op == 1:
            if front_size == 0:
                while back_size > 0:
                    back_size -= 1
                    let a = back_a[back_size]
                    let b = back_b[back_size]
                    if front_size == 0:
                        front_a[front_size] = a
                        front_b[front_size] = b
                    else:
                        front_a[front_size] = front_a[front_size - 1] * a % MODULUS
                        front_b[front_size] = (front_a[front_size - 1] * b + front_b[front_size - 1]) % MODULUS
                    front_size += 1
            if front_size == 0: return -1
            front_size -= 1
        elif op == 2:
            if c_size_t(pos) >= length: return -1
            let x = values[pos]
            pos += 1
            if x < 0 or x >= MODULUS: return -1
            var answer = x
            if front_size > 0: answer = (front_a[front_size - 1] * answer + front_b[front_size - 1]) % MODULUS
            if back_size > 0: answer = (agg_a[back_size - 1] * answer + agg_b[back_size - 1]) % MODULUS
            query += 1
            checksum += query * (answer + 1)
        else:
            return -1
    if c_size_t(pos) != length: return -1
    return checksum
