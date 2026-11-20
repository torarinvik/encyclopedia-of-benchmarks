from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], at: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[at + b] = UInt8((bits >> (8 * b)) & 255)

@export("bagwell_functional_hash_list")
fn bagwell_functional_hash_list(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 131: return -1
    let n64 = input[0]
    if n64 < 0 or n64 > 32: return -1
    let n = Int(n64)
    let q_at = 1 + 2*n
    if q_at >= Int(length): return -1
    let q64 = input[q_at]
    if q64 < 1 or q64 > 32: return -1
    let q = Int(q64)
    let query_at = q_at + 1
    if length != c_size_t(2 + 2*n + 2*q): return -1
    for i in range(n):
        if input[1+2*i] < -2147483648 or input[1+2*i] > 2147483647 or
            input[2+2*i] < -2147483648 or input[2+2*i] > 2147483647: return -1
    for j in range(q):
        let root = input[query_at+2*j]
        let key = input[query_at+2*j+1]
        if root < 0 or root > n64 or key < -2147483648 or key > 2147483647: return -1
    let output_bytes = 8*q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2

    var keys = InlineArray[Int64, 56]()
    var values = InlineArray[Int64, 56]()
    var next = InlineArray[Int32, 56]()
    var heads = InlineArray[Int32, 56]()
    var prev = InlineArray[Int32, 3]()
    var root_block = InlineArray[Int32, 33]()
    var root_offset = InlineArray[Int32, 33]()
    for i in range(56): next[i] = -1; heads[i] = -1
    for i in range(3): prev[i] = -1
    for i in range(33): root_block[i] = -1; root_offset[i] = -1
    var current = 0
    for i in range(n):
        if i == 8 or i == 24: prev[current+1] = Int32(current); current += 1
        let start = 0 if current == 0 else (8 if current == 1 else 24)
        let side = 8 if current == 0 else (16 if current == 1 else 32)
        let offset = i - start
        let slot = start + offset
        let key = input[1+2*i]
        let bucket_slot = start + Int(key & Int64(side-1))
        keys[slot] = key
        values[slot] = input[2+2*i]
        next[slot] = heads[bucket_slot]
        heads[bucket_slot] = Int32(offset)
        root_block[i+1] = Int32(current)
        root_offset[i+1] = Int32(offset)
    for j in range(q):
        let root = Int(input[query_at+2*j])
        let key = input[query_at+2*j+1]
        var block = Int(root_block[root])
        let limit = Int(root_offset[root])
        var answer: Int64 = -9223372036854775807 - 1
        if block >= 0:
            var first = True
            while block >= 0 and answer == -9223372036854775807 - 1:
                let start = 0 if block == 0 else (8 if block == 1 else 24)
                let side = 8 if block == 0 else (16 if block == 1 else 32)
                let bucket_slot = start + Int(key & Int64(side-1))
                var chain = Int(heads[bucket_slot])
                while chain >= 0:
                    let slot = start + chain
                    if (not first or chain <= limit) and keys[slot] == key:
                        answer = values[slot]
                        break
                    chain = Int(next[slot])
                block = Int(prev[block])
                first = False
        put_i64_le(output, 8*j, answer)
    return Int64(output_bytes)
