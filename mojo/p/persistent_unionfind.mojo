from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_Q = 64
alias MAX_INPUT_VALUES = 2 + 4 * MAX_Q

fn puf_find_root(parent: InlineArray[Int, MAX_N], item: Int) -> Int:
    var current = item
    while parent[current] != current:
        current = parent[current]
    return current

fn puf_visit_version(node: Int, kind: InlineArray[Int64, MAX_Q],
    u: InlineArray[Int64, MAX_Q], v: InlineArray[Int64, MAX_Q],
    first_child: InlineArray[Int, MAX_Q + 1], next_sibling: InlineArray[Int, MAX_Q],
    mut parent: InlineArray[Int, MAX_N], mut set_size: InlineArray[Int, MAX_N],
    mut answer: InlineArray[Int64, MAX_Q + 1],
    mut history_child: InlineArray[Int, MAX_Q], mut history_root: InlineArray[Int, MAX_Q],
    mut history_size: InlineArray[Int, MAX_Q], mut history_count: Int):
    let saved_history = history_count
    if node != 0:
        let operation = node - 1
        if kind[operation] == 0:
            var root_u = puf_find_root(parent, Int(u[operation]))
            var root_v = puf_find_root(parent, Int(v[operation]))
            if root_u == root_v:
                history_child[history_count] = -1
                history_root[history_count] = -1
                history_size[history_count] = 0
            else:
                if set_size[root_u] > set_size[root_v]:
                    let temporary = root_u
                    root_u = root_v
                    root_v = temporary
                history_child[history_count] = root_u
                history_root[history_count] = root_v
                history_size[history_count] = set_size[root_v]
                parent[root_u] = root_v
                set_size[root_v] += set_size[root_u]
            history_count += 1
        else:
            if puf_find_root(parent, Int(u[operation])) == puf_find_root(parent, Int(v[operation])):
                answer[node] = 1
            else:
                answer[node] = 0
    var child = first_child[node]
    while child >= 0:
        puf_visit_version(child, kind, u, v, first_child, next_sibling,
            mut parent, mut set_size, mut answer, mut history_child,
            mut history_root, mut history_size, mut history_count)
        child = next_sibling[child - 1]
    while history_count > saved_history:
        history_count -= 1
        let changed_child = history_child[history_count]
        if changed_child >= 0:
            let root = history_root[history_count]
            parent[changed_child] = changed_child
            set_size[root] = history_size[history_count]

fn puf_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("persistent_unionfind")
fn persistent_unionfind(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + 4 * q):
        return -1

    var kind = InlineArray[Int64, MAX_Q]()
    var u = InlineArray[Int64, MAX_Q]()
    var v = InlineArray[Int64, MAX_Q]()
    var first_child = InlineArray[Int, MAX_Q + 1]()
    var next_sibling = InlineArray[Int, MAX_Q]()
    var answer = InlineArray[Int64, MAX_Q + 1]()
    for node in range(q + 1):
        first_child[node] = -1
    var query_count = 0
    for operation in range(q):
        let offset = 2 + 4 * operation
        kind[operation] = input[offset]
        let version = input[offset + 1]
        u[operation] = input[offset + 2]
        v[operation] = input[offset + 3]
        if (kind[operation] != 0 and kind[operation] != 1) or version < -1 or
            version >= Int64(operation) or u[operation] < 0 or u[operation] >= n_value or
            v[operation] < 0 or v[operation] >= n_value:
            return -1
        if version >= 0 and kind[Int(version)] != 0:
            return -1
        if kind[operation] == 1:
            query_count += 1
        let parent_node = Int(version + 1)
        next_sibling[operation] = first_child[parent_node]
        first_child[parent_node] = operation + 1

    let required = 8 * query_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var parent = InlineArray[Int, MAX_N]()
    var set_size = InlineArray[Int, MAX_N]()
    for item in range(n):
        parent[item] = item
        set_size[item] = 1
    var history_child = InlineArray[Int, MAX_Q]()
    var history_root = InlineArray[Int, MAX_Q]()
    var history_size = InlineArray[Int, MAX_Q]()
    var history_count = 0
    puf_visit_version(0, kind, u, v, first_child, next_sibling,
        mut parent, mut set_size, mut answer, mut history_child,
        mut history_root, mut history_size, mut history_count)
    var written = 0
    for operation in range(q):
        if kind[operation] == 1:
            puf_store_i64_le(output, written, answer[operation + 1])
            written += 8
    return Int64(written)
