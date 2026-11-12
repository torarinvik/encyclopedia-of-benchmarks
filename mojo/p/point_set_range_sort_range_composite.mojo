from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MODULUS = 998244353
alias MAX_LENGTH = 210

struct Record:
    priority: Int64
    a: Int64
    b: Int64

@export("point_set_range_sort_range_composite")
fn point_set_range_sort_range_composite(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_LENGTH):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > 16 or q_value < 1 or q_value > 32:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length < c_size_t(2 + 3 * n):
        return -1
    var records = InlineArray[Record, 16]()
    var seen = InlineArray[Int64, 48]()
    var seen_count = 0
    var cursor = 2
    for i in range(n):
        let p = input[cursor]
        let a = input[cursor + 1]
        let b = input[cursor + 2]
        cursor += 3
        if p < 0 or p > 1_000_000_000 or a < 1 or a >= MODULUS or b < 0 or b >= MODULUS:
            return -1
        for j in range(seen_count):
            if seen[j] == p:
                return -1
        seen[seen_count] = p
        seen_count += 1
        records[i] = Record(p, a, b)

    var checksum: Int64 = 0
    var query_number: Int64 = 0
    for _ in range(q):
        if cursor >= Int(length):
            return -1
        let opcode = input[cursor]
        cursor += 1
        if opcode == 0:
            if Int(length) - cursor < 4:
                return -1
            let index = input[cursor]
            let p = input[cursor + 1]
            let a = input[cursor + 2]
            let b = input[cursor + 3]
            cursor += 4
            if index < 0 or index >= n_value or p < 0 or p > 1_000_000_000 or a < 1 or a >= MODULUS or b < 0 or b >= MODULUS:
                return -1
            for j in range(seen_count):
                if seen[j] == p:
                    return -1
            seen[seen_count] = p
            seen_count += 1
            records[Int(index)] = Record(p, a, b)
        elif opcode == 1:
            if Int(length) - cursor < 3:
                return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            let x = input[cursor + 2]
            cursor += 3
            if left < 0 or left >= right or right > n_value or x < 0 or x >= MODULUS:
                return -1
            var answer = x
            for i in range(Int(left), Int(right)):
                answer = (records[i].a * answer + records[i].b) % MODULUS
            query_number += 1
            checksum = (checksum + query_number * answer) % MODULUS
        elif opcode == 2 or opcode == 3:
            if Int(length) - cursor < 2:
                return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            cursor += 2
            if left < 0 or left >= right or right > n_value:
                return -1
            for i in range(Int(left) + 1, Int(right)):
                let item = records[i]
                var j = i
                while j > Int(left) and ((opcode == 2 and records[j - 1].priority > item.priority) or (opcode == 3 and records[j - 1].priority < item.priority)):
                    records[j] = records[j - 1]
                    j -= 1
                records[j] = item
        else:
            return -1
    if cursor != Int(length):
        return -1
    return checksum
