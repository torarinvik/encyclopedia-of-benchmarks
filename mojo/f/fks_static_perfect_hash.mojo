from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn fks_hash_index(a: Int, b: Int, modulus: Int, key: Int) -> Int:
    return ((a * key + b) % 257) % modulus

@export("fks_static_perfect_hash")
fn fks_static_perfect_hash(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 19: return -1
    let nr = input[0]
    let qr = input[1]
    if nr < 0 or nr > 8 or qr < 0 or qr > 8: return -1
    let n = Int(nr)
    let q = Int(qr)
    if length != c_size_t(2 + n + q): return -1
    for i in range(n + q):
        if input[2 + i] < 0 or input[2 + i] > 255: return -1
    for i in range(n):
        for j in range(i + 1, n):
            if input[2 + i] == input[2 + j]: return -1

    var bucket_of = InlineArray[Int, 8](fill=0)
    var bucket_sizes = InlineArray[Int, 8](fill=0)
    var first_a = 0
    var first_b = 0
    var first_found = n == 0
    for a in range(1, 257):
        if first_found: break
        for b in range(257):
            if first_found: break
            var counts = InlineArray[Int, 8](fill=0)
            for i in range(n): counts[fks_hash_index(a, b, n, Int(input[2 + i]))] += 1
            var square_sum = 0
            for bucket in range(n): square_sum += counts[bucket] * counts[bucket]
            if square_sum <= 4 * n:
                first_a = a
                first_b = b
                first_found = True
    if not first_found: return -1
    for i in range(n):
        bucket_of[i] = fks_hash_index(first_a, first_b, n, Int(input[2 + i]))
        bucket_sizes[bucket_of[i]] += 1

    var slot_keys = InlineArray[Int64, 512](fill=0)
    var occupied = InlineArray[Bool, 512](fill=False)
    var local_a = InlineArray[Int, 8](fill=0)
    var local_b = InlineArray[Int, 8](fill=0)
    for bucket in range(n):
        let count = bucket_sizes[bucket]
        if count == 0: continue
        let capacity = count * count
        var local_found = False
        for a in range(1, 257):
            if local_found: break
            for b in range(257):
                if local_found: break
                var used = InlineArray[Bool, 64](fill=False)
                var collision = False
                for i in range(n):
                    if bucket_of[i] == bucket:
                        let position = fks_hash_index(a, b, capacity, Int(input[2 + i]))
                        if used[position]:
                            collision = True
                        else:
                            used[position] = True
                if not collision:
                    local_a[bucket] = a
                    local_b[bucket] = b
                    for i in range(n):
                        if bucket_of[i] == bucket:
                            let position = fks_hash_index(a, b, capacity, Int(input[2 + i]))
                            slot_keys[bucket * 64 + position] = input[2 + i]
                            occupied[bucket * 64 + position] = True
                    local_found = True
        if not local_found: return -1

    var result: Int64 = 0
    for i in range(q):
        var present = False
        if n > 0:
            let query = input[2 + n + i]
            let bucket = fks_hash_index(first_a, first_b, n, Int(query))
            let count = bucket_sizes[bucket]
            let capacity = count * count
            if capacity > 0:
                let position = fks_hash_index(local_a[bucket], local_b[bucket], capacity, Int(query))
                let slot = bucket * 64 + position
                present = occupied[slot] and slot_keys[slot] == query
        if present: result |= Int64(1) << i
    return result
