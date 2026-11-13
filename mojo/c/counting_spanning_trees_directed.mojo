from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(998244353)

fn modular_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if exponent % 2 == 1: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent //= 2
    return result

@export("counting_spanning_trees_directed")
fn counting_spanning_trees_directed(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 27: return -1
    let n64 = values[0]
    let m64 = values[1]
    let root64 = values[2]
    if n64 < 1 or n64 > 6 or m64 < 0 or m64 > 12 or root64 < 0 or root64 >= n64: return -1
    let n = Int(n64)
    let m = Int(m64)
    let root = Int(root64)
    if length != c_size_t(3 + 2 * m): return -1
    var matrix = InlineArray[Int64, 36](fill=0)
    for edge in range(m):
        let u64 = values[3 + 2 * edge]
        let v64 = values[4 + 2 * edge]
        if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64: return -1
        let u = Int(u64)
        let v = Int(v64)
        if u == v or v == root: continue
        var row = v
        if v > root: row -= 1
        matrix[6 * row + row] = (matrix[6 * row + row] + 1) % MODULUS
        if u != root:
            var column = u
            if u > root: column -= 1
            matrix[6 * row + column] = (matrix[6 * row + column] + MODULUS - 1) % MODULUS
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    let dimension = n - 1
    var determinant: Int64 = 1
    for column in range(dimension):
        var pivot = column
        while pivot < dimension and matrix[6 * pivot + column] == 0: pivot += 1
        if pivot == dimension:
            determinant = 0
            break
        if pivot != column:
            for j in range(dimension):
                let temporary = matrix[6 * pivot + j]
                matrix[6 * pivot + j] = matrix[6 * column + j]
                matrix[6 * column + j] = temporary
            determinant = (MODULUS - determinant) % MODULUS
        let diagonal = matrix[6 * column + column]
        determinant = determinant * diagonal % MODULUS
        let inverse = modular_power(diagonal, MODULUS - 2)
        for row in range(column + 1, dimension):
            let factor = matrix[6 * row + column] * inverse % MODULUS
            for j in range(column, dimension):
                matrix[6 * row + j] = (matrix[6 * row + j] - factor * matrix[6 * column + j] % MODULUS + MODULUS) % MODULUS
    let bits = UInt64(determinant)
    for byte in range(8): output[byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return 8
