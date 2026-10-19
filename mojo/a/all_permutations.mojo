from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn permutation_store(output: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: Int32):
    let bits = UInt32(value)
    for b in range(4):
        output[pos + b] = UInt8((bits >> (8 * b)) & 255)

fn permutation_generate(values: List[Int32], mut current: List[Int32], mut used: List[Bool],
                        depth: Int, n: Int, output: UnsafePointer[UInt8, MutAnyOrigin],
                        mut result_count: Int):
    if depth == n:
        let start = result_count * n * 4
        for i in range(n):
            permutation_store(output, start + 4 * i, current[i])
        result_count += 1
        return
    for i in range(n):
        if used[i]:
            continue
        current[depth] = values[i]
        used[i] = True
        permutation_generate(values, current, used, depth + 1, n, output, result_count)
        used[i] = False

@export("all_permutations")
fn all_permutations(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 7:
        return -1
    if input[0] < 0 or input[0] > 6 or length != c_size_t(input[0] + 1):
        return -1
    let n = Int(input[0])
    var values = List[Int32](length=n, fill=0)
    for i in range(n):
        if input[i + 1] < -2147483648 or input[i + 1] > 2147483647:
            return -1
        values[i] = Int32(input[i + 1])
    var count = 1
    for i in range(2, n + 1):
        count *= i
    let required = count * n * 4
    if capacity < c_size_t(required) or (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    var current = List[Int32](length=n, fill=0)
    var used = List[Bool](length=n, fill=False)
    var emitted = 0
    permutation_generate(values, current, used, 0, n, output, emitted)
    return Int64(emitted)
