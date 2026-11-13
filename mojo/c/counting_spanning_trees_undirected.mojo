from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MODULUS = Int64(1000000007)

fn modular_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if exponent % 2 == 1: result = result * base % MODULUS
        base = base * base % MODULUS
        exponent //= 2
    return result

@export("counting_spanning_trees_undirected")
fn counting_spanning_trees_undirected(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 44: return -1
    let n64 = values[0]
    let m64 = values[1]
    if n64 < 1 or n64 > 7 or m64 < 0 or m64 > 21: return -1
    let n = Int(n64)
    let m = Int(m64)
    if length != c_size_t(2 + 2 * m): return -1
    var seen = InlineArray[Bool, 49](fill=False)
    var matrix = InlineArray[Int64, 49](fill=0)
    for edge in range(m):
        let u64 = values[2 + 2 * edge]
        let v64 = values[3 + 2 * edge]
        if u64 < 0 or u64 >= n64 or v64 < 0 or v64 >= n64 or u64 == v64: return -1
        let u = Int(u64)
        let v = Int(v64)
        if seen[7 * u + v]: return -1
        seen[7 * u + v] = True
        seen[7 * v + u] = True
        matrix[7 * u + u] += 1
        matrix[7 * v + v] += 1
        matrix[7 * u + v] = (matrix[7 * u + v] + MODULUS - 1) % MODULUS
        matrix[7 * v + u] = (matrix[7 * v + u] + MODULUS - 1) % MODULUS
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var determinant: Int64 = 1
    for column in range(n - 1):
        var pivot = column
        while pivot < n - 1 and matrix[7 * pivot + column] == 0: pivot += 1
        if pivot == n - 1:
            determinant = 0
            break
        if pivot != column:
            for j in range(n - 1):
                let temporary = matrix[7 * pivot + j]
                matrix[7 * pivot + j] = matrix[7 * column + j]
                matrix[7 * column + j] = temporary
            determinant = (MODULUS - determinant) % MODULUS
        let diagonal = matrix[7 * column + column]
        determinant = determinant * diagonal % MODULUS
        let inverse = modular_power(diagonal, MODULUS - 2)
        for row in range(column + 1, n - 1):
            let factor = matrix[7 * row + column] * inverse % MODULUS
            for j in range(column, n - 1):
                matrix[7 * row + j] = (matrix[7 * row + j] - factor * matrix[7 * column + j] % MODULUS + MODULUS) % MODULUS
    let bits = UInt64(determinant)
    for byte in range(8): output[byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return 8
