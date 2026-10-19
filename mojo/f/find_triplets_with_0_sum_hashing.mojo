from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn triplet_hash(value: Int64) -> Int64: return ((value + 100000) * 37) % 128

@export("find_triplets_with_0_sum_hashing")
fn find_triplets_with_0_sum_hashing(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if length > 64 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(length):
        if input[i] < -100000 or input[i] > 100000: return -1
    var triples = InlineArray[Int64, 6144](0)
    var count: Int64 = 0
    for i in range(length):
        if i + 2 >= length: break
        var keys = InlineArray[Int64, 128](0)
        var occupied = InlineArray[Bool, 128](False)
        for j in range(i + 1, length):
            let other = input[j]
            let required = -input[i] - other
            if required >= -100000 and required <= 100000:
                var slot = triplet_hash(required)
                var probes: Int64 = 0
                while probes < 128 and occupied[slot] and keys[slot] != required:
                    slot = (slot + 1) % 128
                    probes += 1
                if probes < 128 and occupied[slot] and keys[slot] == required:
                    var a = input[i]
                    var b = other
                    var c = required
                    if a > b: let t = a; a = b; b = t
                    if b > c: let t = b; b = c; c = t
                    if a > b: let t = a; a = b; b = t
                    var duplicate = False
                    for t in range(count):
                        if triples[3 * t] == a and triples[3 * t + 1] == b and triples[3 * t + 2] == c: duplicate = True
                    if not duplicate and count < 2048:
                        triples[3 * count] = a
                        triples[3 * count + 1] = b
                        triples[3 * count + 2] = c
                        count += 1
            var slot_add = triplet_hash(other)
            var probes_add: Int64 = 0
            while probes_add < 128 and occupied[slot_add] and keys[slot_add] != other:
                slot_add = (slot_add + 1) % 128
                probes_add += 1
            if probes_add < 128:
                keys[slot_add] = other
                occupied[slot_add] = True
    if count == 0: return 0
    let bytes = count * 12
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < bytes: return -2
    for i in range(count * 3):
        let bits = UInt32(Int32(triples[i]))
        for b in range(4): output[i * 4 + b] = UInt8((bits >> (8 * b)) & 255)
    return count
