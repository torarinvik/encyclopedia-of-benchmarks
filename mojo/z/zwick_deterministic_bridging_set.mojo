from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn popcount16(mask: UInt16) -> Int:
    var value = mask
    var count = 0
    while value != 0:
        count += Int(value & UInt16(1))
        value = value >> 1
    return count

fn subpath(inout witness: InlineArray[UInt8, 64], n: Int, from_vertex: Int,
           to_vertex: Int, limit: Int, inout output: InlineArray[UInt8, 8],
           offset: Int) -> Int:
    if limit <= 0 or witness[from_vertex*n+to_vertex] == 0: return 0
    let middle = Int(witness[from_vertex*n+to_vertex]) - 1
    var count = subpath(witness, n, from_vertex, middle, limit-1, output, offset)
    output[offset+count] = UInt8(middle)
    count += 1
    let remaining = limit-count
    if remaining > 0:
        count += subpath(witness, n, middle, to_vertex, remaining, output, offset+count)
    return count

@export("zwick_deterministic_bridging_set")
fn zwick_deterministic_bridging_set(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                   length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 131: return -1
    if input[0] < 2 or input[0] > 8: return -1
    let n = Int(input[0])
    if input[1] < 2 or input[1] > input[0] or length != c_size_t(2+2*n*n): return -1
    let threshold = Int(input[1])
    var edge = InlineArray[UInt8, 64](fill=0)
    var witness = InlineArray[UInt8, 64](fill=0)
    var distance = InlineArray[UInt8, 64](fill=0)
    let matrix = n*n
    for index in range(matrix):
        if input[2+index] < 0 or input[2+index] > 1: return -1
        if input[2+matrix+index] < 0 or input[2+matrix+index] > n: return -1
        edge[index] = UInt8(input[2+index])
        witness[index] = UInt8(input[2+matrix+index])
    for i in range(n):
        if edge[i*n+i] != 0: return -1
        for j in range(n):
            distance[i*n+j] = UInt8(0 if i == j else (1 if edge[i*n+j] != 0 else 9))
    for k in range(n):
        for i in range(n):
            for j in range(n):
                let candidate = Int(distance[i*n+k]) + Int(distance[k*n+j])
                if candidate < Int(distance[i*n+j]): distance[i*n+j] = UInt8(candidate)
    for i in range(n):
        for j in range(n):
            let d = Int(distance[i*n+j])
            let encoded = Int(witness[i*n+j])
            if d >= 9: return -1
            if d <= 1:
                if encoded != 0: return -1
            else:
                if encoded == 0: return -1
                let middle = encoded-1
                if middle == i or middle == j: return -1
                let left = Int(distance[i*n+middle])
                let right = Int(distance[middle*n+j])
                if left+right != d or left >= d or right >= d: return -1

    var constraints = InlineArray[UInt16, 64](fill=0)
    var constraint_count = 0
    for i in range(n):
        for j in range(n):
            var internal = InlineArray[UInt8, 8](fill=0)
            let count = subpath(witness, n, i, j, threshold, internal, 0)
            var mask = (UInt16(1) << i) | (UInt16(1) << j)
            for k in range(count): mask |= UInt16(1) << Int(internal[k])
            if popcount16(mask) >= threshold:
                var duplicate = False
                for c in range(constraint_count):
                    if constraints[c] == mask: duplicate = True
                if not duplicate:
                    constraints[constraint_count] = mask
                    constraint_count += 1
    var unhit = InlineArray[Bool, 64](fill=False)
    for c in range(constraint_count): unhit[c] = True
    var remaining = constraint_count
    var selected: UInt16 = 0
    while remaining > 0:
        var best_vertex = 0
        var best_score = 0
        for v in range(n):
            var score = 0
            for c in range(constraint_count):
                if unhit[c] and (constraints[c] & (UInt16(1) << v)) != 0: score += 1
            if score > best_score:
                best_score = score
                best_vertex = v
        if best_score == 0: return -1
        selected |= UInt16(1) << best_vertex
        for c in range(constraint_count):
            if unhit[c] and (constraints[c] & (UInt16(1) << best_vertex)) != 0:
                unhit[c] = False
                remaining -= 1
    return Int64(selected)
