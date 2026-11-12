from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_Q = 64
comptime MODULUS = 998_244_353

fn normalize(value_input: Int64) -> Int64:
    var value = value_input % MODULUS
    if value < 0: value += MODULUS
    return value

fn identity() -> InlineArray[Int64, 4]:
    var result = InlineArray[Int64, 4]()
    result[0] = 1
    result[3] = 1
    return result

fn multiply(left: InlineArray[Int64, 4], right: InlineArray[Int64, 4]) -> InlineArray[Int64, 4]:
    var result = InlineArray[Int64, 4]()
    for row in range(2):
        for column in range(2):
            for inner in range(2):
                let index = 2 * row + column
                result[index] = normalize(result[index] + left[2 * row + inner] * right[2 * inner + column])
    return result

fn inverse(matrix: InlineArray[Int64, 4]) -> InlineArray[Int64, 4]:
    var result = InlineArray[Int64, 4]()
    result[0] = matrix[3]
    result[1] = normalize(-matrix[1])
    result[2] = normalize(-matrix[2])
    result[3] = matrix[0]
    return result

fn matrix_equal(left: InlineArray[Int64, 4], right: InlineArray[Int64, 4]) -> Bool:
    for cell in range(4):
        if left[cell] != right[cell]: return False
    return True

fn find_root(inout parent: InlineArray[Int, 32],
    inout difference: InlineArray[InlineArray[Int64, 4], 32], item: Int) -> Int:
    if parent[item] != item:
        let old_parent = parent[item]
        let root = find_root(parent, difference, old_parent)
        difference[item] = multiply(difference[old_parent], difference[item])
        parent[item] = root
    return parent[item]

fn read_matrix(input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int) -> InlineArray[Int64, 4]:
    var matrix = InlineArray[Int64, 4]()
    for cell in range(4): matrix[cell] = input[offset + cell]
    return matrix

fn write_i64_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("unionfind_with_potential_non_commutative_group")
fn unionfind_with_potential_non_commutative_group(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    if length < 9 or length > c_size_t(2 + 7 * MAX_Q): return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + 7 * q): return -1
    for operation in range(q):
        let position = 2 + 7 * operation
        let kind = input[position]
        let u = input[position + 1]
        let v = input[position + 2]
        if u < 0 or u >= n_value or v < 0 or v >= n_value: return -1
        if kind == 0:
            let matrix = read_matrix(input, position + 3)
            for cell in range(4):
                if matrix[cell] < 0 or matrix[cell] >= MODULUS: return -1
            if normalize(matrix[0] * matrix[3] - matrix[1] * matrix[2]) != 1: return -1
        elif kind == 1:
            for cell in range(4):
                if input[position + 3 + cell] != 0: return -1
        else:
            return -1
    let required = 32 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    var parent = InlineArray[Int, 32]()
    var set_size = InlineArray[Int, 32]()
    var difference = InlineArray[InlineArray[Int64, 4], 32]()
    for item in range(n):
        parent[item] = item
        set_size[item] = 1
        difference[item] = identity()
    for operation in range(q):
        let position = 2 + 7 * operation
        let kind = input[position]
        let u = Int(input[position + 1])
        let v = Int(input[position + 2])
        var row = InlineArray[Int64, 4]()
        let root_u = find_root(parent, difference, u)
        let root_v = find_root(parent, difference, v)
        if kind == 1:
            if root_u == root_v:
                row = multiply(inverse(difference[v]), difference[u])
            else:
                for cell in range(4): row[cell] = -1
        else:
            let relation = read_matrix(input, position + 3)
            if root_u == root_v:
                row[0] = Int64(matrix_equal(multiply(inverse(difference[v]), difference[u]), relation))
            elif set_size[root_u] < set_size[root_v]:
                difference[root_u] = multiply(multiply(difference[v], relation), inverse(difference[u]))
                parent[root_u] = root_v
                set_size[root_v] += set_size[root_u]
                row[0] = 1
            else:
                difference[root_v] = multiply(multiply(difference[u], inverse(relation)), inverse(difference[v]))
                parent[root_v] = root_u
                set_size[root_u] += set_size[root_v]
                row[0] = 1
        for cell in range(4): write_i64_le(row[cell], output, 32 * operation + 8 * cell)
    return Int64(required)
