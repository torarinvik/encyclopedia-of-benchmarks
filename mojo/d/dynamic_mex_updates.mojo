from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dmu_tree_set(inout tree: InlineArray[Int32, 128], base: Int, value: Int, present: Int32):
    var node = base + value
    tree[node] = present
    node //= 2
    while node > 0:
        tree[node] = tree[2 * node] + tree[2 * node + 1]
        node //= 2

fn dmu_find_mex(tree: InlineArray[Int32, 128], base: Int, domain: Int) -> Int:
    var node = 1
    var start = 0
    var span = base
    while span > 1:
        let half = span // 2
        let left_width = if start >= domain: 0 else: min(half, domain - start)
        if Int(tree[2 * node]) < left_width:
            node *= 2
            span = half
        else:
            node = 2 * node + 1
            start += half
            span = half
    return start

fn dmu_write_i64(inout staged: InlineArray[UInt8, 256], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        staged[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("dynamic_mex_updates")
fn dynamic_mex_updates(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 99:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > 32 or q_value < 0 or q_value > 32:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if Int(length) != 2 + n + 2 * q:
        return -1

    var current = InlineArray[Int64, 32]()
    var update_indices = InlineArray[Int32, 32]()
    var update_values = InlineArray[Int64, 32]()
    for index in range(n):
        let value = input[2 + index]
        if value < -1000 or value > 1000:
            return -1
        current[index] = value
    var cursor = 2 + n
    for operation in range(q):
        let index = input[cursor]
        let value = input[cursor + 1]
        cursor += 2
        if index < 0 or index >= n_value or value < -1000 or value > 1000:
            return -1
        update_indices[operation] = Int32(index)
        update_values[operation] = value

    let needed = 8 * q
    if needed > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < needed):
        return -2
    var base = 1
    while base < n + 1:
        base *= 2
    var frequencies = InlineArray[Int32, 33]()
    var tree = InlineArray[Int32, 128]()
    for index in range(n):
        let value = current[index]
        if value >= 0 and value <= n_value:
            frequencies[Int(value)] += 1
    for value in range(n + 1):
        tree[base + value] = if frequencies[value] > 0: 1 else: 0
    var node = base
    while node > 1:
        node -= 1
        tree[node] = tree[2 * node] + tree[2 * node + 1]

    var staged = InlineArray[UInt8, 256]()
    for operation in range(q):
        let index = Int(update_indices[operation])
        let old_value = current[index]
        let new_value = update_values[operation]
        if old_value != new_value:
            if old_value >= 0 and old_value <= n_value:
                let old_index = Int(old_value)
                frequencies[old_index] -= 1
                if frequencies[old_index] == 0:
                    dmu_tree_set(inout tree, base, old_index, 0)
            if new_value >= 0 and new_value <= n_value:
                let new_index = Int(new_value)
                if frequencies[new_index] == 0:
                    dmu_tree_set(inout tree, base, new_index, 1)
                frequencies[new_index] += 1
            current[index] = new_value
        dmu_write_i64(inout staged, 8 * operation, Int64(dmu_find_mex(tree, base, n + 1)))
    for byte in range(needed):
        output[byte] = staged[byte]
    return Int64(needed)
