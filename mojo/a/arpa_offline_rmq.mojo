from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 64
const MAX_Q = 64
const MAX_INPUT_LENGTH = 195

@export("arpa_offline_rmq")
fn arpa_offline_rmq(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH: return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n + 2 * q): return -1
    for i in range(n):
        if input[2 + i] < -1000 or input[2 + i] > 1000: return -1
    let query_start = 2 + n
    for j in range(q):
        let left = input[query_start + 2 * j]
        let right = input[query_start + 2 * j + 1]
        if left < 0 or left > right or right >= n_value: return -1
    var parent = InlineArray[Int64, 64](fill=0)
    var stack = InlineArray[Int64, 64](fill=0)
    var head = InlineArray[Int64, 64](fill=-1)
    var query_next = InlineArray[Int64, 64](fill=0)
    for i in range(n): parent[i] = Int64(i)
    for j in range(q):
        let bucket = Int(input[query_start + 2 * j + 1])
        query_next[j] = head[bucket]
        head[bucket] = Int64(j)
    var checksum: Int64 = 0
    var stack_size = 0
    for right in range(n):
        while stack_size > 0 and input[2 + Int(stack[stack_size - 1])] > input[2 + right]:
            stack_size -= 1
            parent[Int(stack[stack_size])] = Int64(right)
        stack[stack_size] = Int64(right)
        stack_size += 1
        var query = head[right]
        while query >= 0:
            let ordinal = Int(query)
            var node = Int(input[query_start + 2 * ordinal])
            var root = node
            while Int(parent[root]) != root: root = Int(parent[root])
            while Int(parent[node]) != node:
                let next = Int(parent[node])
                parent[node] = Int64(root)
                node = next
            checksum += Int64(ordinal + 1) * Int64(root + 1)
            query = query_next[ordinal]
    return checksum
