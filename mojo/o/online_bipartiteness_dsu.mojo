from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 32
const MAX_Q = 64
const MAX_INPUT_LENGTH = 195

@export("online_bipartiteness_dsu")
fn online_bipartiteness_dsu(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH: return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + 3 * q): return -1
    for j in range(q):
        let opcode = input[2 + 3 * j]
        let a = input[3 + 3 * j]
        let b = input[4 + 3 * j]
        if opcode == 0:
            if a < 0 or a >= n_value or b < 0 or b >= n_value: return -1
        elif opcode == 1:
            if a < 0 or a >= n_value or b != 0: return -1
        else:
            return -1
    var parent = InlineArray[Int64, 32](fill=0)
    var size = InlineArray[Int64, 32](fill=0)
    var parity = InlineArray[Int64, 32](fill=0)
    var bad = InlineArray[Bool, 32](fill=False)
    for i in range(n):
        parent[i] = Int64(i)
        size[i] = 1
    var checksum: Int64 = 0
    var query_ordinal: Int64 = 0
    for operation in range(q):
        let opcode = input[2 + 3 * operation]
        let a = Int(input[3 + 3 * operation])
        if opcode == 1:
            var root = a
            var total: Int64 = 0
            while Int(parent[root]) != root:
                total ^= parity[root]
                root = Int(parent[root])
            var current = a
            var accumulated: Int64 = 0
            while Int(parent[current]) != current:
                let next = Int(parent[current])
                let edge = parity[current]
                parent[current] = Int64(root)
                parity[current] = total ^ accumulated
                accumulated ^= edge
                current = next
            let answer: Int64 = 1 if not bad[root] else 0
            checksum += (query_ordinal + 1) * (answer + 1)
            query_ordinal += 1
            continue
        let b = Int(input[4 + 3 * operation])
        var root_a = a
        var total_a: Int64 = 0
        while Int(parent[root_a]) != root_a:
            total_a ^= parity[root_a]
            root_a = Int(parent[root_a])
        var current_a = a
        var accumulated_a: Int64 = 0
        while Int(parent[current_a]) != current_a:
            let next_a = Int(parent[current_a])
            let edge_a = parity[current_a]
            parent[current_a] = Int64(root_a)
            parity[current_a] = total_a ^ accumulated_a
            accumulated_a ^= edge_a
            current_a = next_a
        var root_b = b
        var total_b: Int64 = 0
        while Int(parent[root_b]) != root_b:
            total_b ^= parity[root_b]
            root_b = Int(parent[root_b])
        var current_b = b
        var accumulated_b: Int64 = 0
        while Int(parent[current_b]) != current_b:
            let next_b = Int(parent[current_b])
            let edge_b = parity[current_b]
            parent[current_b] = Int64(root_b)
            parity[current_b] = total_b ^ accumulated_b
            accumulated_b ^= edge_b
            current_b = next_b
        if root_a == root_b:
            if total_a == total_b: bad[root_a] = True
            continue
        if size[root_a] < size[root_b]:
            let old_root = root_a
            root_a = root_b
            root_b = old_root
            let old_parity = total_a
            total_a = total_b
            total_b = old_parity
        parent[root_b] = Int64(root_a)
        parity[root_b] = total_a ^ total_b ^ 1
        size[root_a] += size[root_b]
        bad[root_a] = bad[root_a] or bad[root_b]
    return checksum
