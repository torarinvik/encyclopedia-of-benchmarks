from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MODULUS: Int64 = 998244353
const MAX_VERTICES: Int = 7
const MAX_EDGES: Int = 9
const MAX_INPUT_LENGTH: Int = 20

fn modular_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = (result * base) % MODULUS
        base = (base * base) % MODULUS
        exponent >>= 1
    return result

@export("counting_eulerian_circuits")
fn counting_eulerian_circuits(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_VERTICES or m_value < 1 or m_value > MAX_EDGES:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m):
        return -1

    var indegree = InlineArray[Int, MAX_VERTICES](fill=0)
    var outdegree = InlineArray[Int, MAX_VERTICES](fill=0)
    var start = 0
    for edge in range(m):
        let u_value = input[2 + 2 * edge]
        let v_value = input[3 + 2 * edge]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        if edge == 0:
            start = u
        outdegree[u] += 1
        indegree[v] += 1

    var balanced = True
    for vertex in range(n):
        if indegree[vertex] != outdegree[vertex]:
            balanced = False
    var answer: Int64 = 0
    if balanced:
        var active_id = InlineArray[Int, MAX_VERTICES](fill=MAX_VERTICES)
        var active_count = 0
        for vertex in range(n):
            if indegree[vertex] != 0:
                active_id[vertex] = active_count
                active_count += 1
        let root_id = active_id[start]
        let dimension = active_count - 1
        var matrix = InlineArray[Int64, MAX_VERTICES * MAX_VERTICES](fill=0)
        for edge in range(m):
            let u = Int(input[2 + 2 * edge])
            let v = Int(input[3 + 2 * edge])
            if u == start:
                continue
            var row = active_id[u]
            if row > root_id:
                row -= 1
            matrix[row * MAX_VERTICES + row] = (matrix[row * MAX_VERTICES + row] + 1) % MODULUS
            if v != start:
                var column = active_id[v]
                if column > root_id:
                    column -= 1
                let index = row * MAX_VERTICES + column
                matrix[index] = (matrix[index] + MODULUS - 1) % MODULUS

        var determinant: Int64 = 1
        for column in range(dimension):
            var pivot = column
            while pivot < dimension and matrix[pivot * MAX_VERTICES + column] == 0:
                pivot += 1
            if pivot == dimension:
                determinant = 0
                break
            if pivot != column:
                for j in range(dimension):
                    let left = column * MAX_VERTICES + j
                    let right = pivot * MAX_VERTICES + j
                    let temporary = matrix[left]
                    matrix[left] = matrix[right]
                    matrix[right] = temporary
                determinant = (MODULUS - determinant) % MODULUS
            let pivot_value = matrix[column * MAX_VERTICES + column]
            determinant = (determinant * pivot_value) % MODULUS
            let inverse = modular_power(pivot_value, MODULUS - 2)
            for row in range(column + 1, dimension):
                let factor = (matrix[row * MAX_VERTICES + column] * inverse) % MODULUS
                for j in range(column, dimension):
                    let index = row * MAX_VERTICES + j
                    matrix[index] = (matrix[index] - factor * matrix[column * MAX_VERTICES + j] % MODULUS + MODULUS) % MODULUS
        answer = determinant
        for vertex in range(n):
            for factor in range(2, outdegree[vertex]):
                answer = (answer * Int64(factor)) % MODULUS

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8:
        return -2
    let encoded = UInt64(answer)
    for byte in range(8):
        output[byte] = UInt8((encoded >> UInt(8 * byte)) & 255)
    return 8
