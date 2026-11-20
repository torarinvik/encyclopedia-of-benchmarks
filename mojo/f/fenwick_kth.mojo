from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("fenwick_kth")
fn fenwick_kth(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 163: return -1
    let nr = input[0]
    let qr = input[1]
    if nr < 1 or nr > 64 or qr < 0 or qr > 32: return -1
    let n = Int(nr)
    let q = Int(qr)
    if length != c_size_t(2 + n + 3 * q): return -1

    var frequency = InlineArray[Int64, 64](fill=0)
    var tree = InlineArray[Int64, 65](fill=0)
    var total: Int64 = 0
    for i in range(n):
        let value = input[2 + i]
        if value < 0 or value > 1000000: return -1
        frequency[i] = value
        total += value
        let index = i + 1
        tree[index] += value
        let parent = index + (index & (0 - index))
        if parent <= n: tree[parent] += tree[index]

    var result: Int64 = 0
    var query_number = 0
    var cursor = 2 + n
    for _ in range(q):
        let opcode = input[cursor]
        let first = input[cursor + 1]
        let second = input[cursor + 2]
        cursor += 3
        if opcode == 0:
            if first < 0 or first >= nr or second < -1000000 or second > 1000000: return -1
            let position = Int(first)
            let updated = frequency[position] + second
            if updated < 0 or updated > 1000000: return -1
            frequency[position] = updated
            total += second
            var index = position + 1
            while index <= n:
                tree[index] += second
                index += index & (0 - index)
        elif opcode == 1:
            if second != 0: return -1
            var answer: Int64 = -1
            if first > 0 and first <= total:
                var index = 0
                var step = 1
                while step <= n / 2: step *= 2
                var rank = first
                while step != 0:
                    let candidate = index + step
                    if candidate <= n and tree[candidate] < rank:
                        index = candidate
                        rank -= tree[candidate]
                    step /= 2
                answer = Int64(index)
            result += Int64(query_number + 1) * (answer + 1)
            query_number += 1
        else:
            return -1
    return result
