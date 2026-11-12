from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 128

fn cartesian_tree_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("cartesian_tree")
fn cartesian_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1 + MAX_N:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(n + 1):
        return -1

    var parent = InlineArray[Int64, MAX_N]()
    var stack = InlineArray[Int, MAX_N]()
    for i in range(n):
        let key = input[i + 1]
        if key < 0 or key > 1_000_000_000:
            return -1
        parent[i] = Int64(i)

    var stack_size = 0
    for i in range(n):
        var last = MAX_N
        while stack_size > 0 and input[stack[stack_size - 1] + 1] > input[i + 1]:
            stack_size -= 1
            last = stack[stack_size]
        if stack_size > 0:
            parent[i] = Int64(stack[stack_size - 1])
        if last < MAX_N:
            parent[last] = Int64(i)
        stack[stack_size] = i
        stack_size += 1

    let output_bytes = n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for i in range(n):
        cartesian_tree_store(output, i * 8, parent[i])
    return Int64(output_bytes)
