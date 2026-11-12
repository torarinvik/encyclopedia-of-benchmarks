from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 256
comptime MODULUS = 998_244_353

fn normalize(value_input: Int64) -> Int64:
    var value = value_input % MODULUS
    if value < 0: value += MODULUS
    return value

fn find_root(inout parent: InlineArray[Int, 64], inout difference: InlineArray[Int64, 64], item: Int) -> Int:
    if parent[item] != item:
        let old_parent = parent[item]
        let root = find_root(parent, difference, old_parent)
        difference[item] = normalize(difference[item] + difference[old_parent])
        parent[item] = root
    return parent[item]

fn put_i64_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("unionfind_with_potential")
fn unionfind_with_potential(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    if length < 6 or length > c_size_t(2 + 4 * MAX_Q): return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + 4 * q): return -1
    for operation in range(q):
        let position = 2 + 4 * operation
        let kind = input[position]
        let u = input[position + 1]
        let v = input[position + 2]
        let x = input[position + 3]
        if u < 0 or u >= n_value or v < 0 or v >= n_value: return -1
        if kind == 0:
            if x < 0 or x >= MODULUS: return -1
        elif kind == 1:
            if x != 0: return -1
        else:
            return -1
    let required = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    var parent = InlineArray[Int, 64]()
    var set_size = InlineArray[Int, 64]()
    var difference = InlineArray[Int64, 64]()
    for item in range(n):
        parent[item] = item
        set_size[item] = 1
    for operation in range(q):
        let position = 2 + 4 * operation
        let kind = input[position]
        let u = Int(input[position + 1])
        let v = Int(input[position + 2])
        let x = input[position + 3]
        let root_u = find_root(parent, difference, u)
        let root_v = find_root(parent, difference, v)
        var answer = Int64(0)
        if kind == 1:
            answer = normalize(difference[u] - difference[v]) if root_u == root_v else -1
        elif root_u == root_v:
            answer = Int64(normalize(difference[u] - difference[v]) == x)
        elif set_size[root_u] < set_size[root_v]:
            parent[root_u] = root_v
            difference[root_u] = normalize(x - difference[u] + difference[v])
            set_size[root_v] += set_size[root_u]
            answer = 1
        else:
            parent[root_v] = root_u
            difference[root_v] = normalize(difference[u] - difference[v] - x)
            set_size[root_u] += set_size[root_v]
            answer = 1
        put_i64_le(answer, output, 8 * operation)
    return Int64(required)
