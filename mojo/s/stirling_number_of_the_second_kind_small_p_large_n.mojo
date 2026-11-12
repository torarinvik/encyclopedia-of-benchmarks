from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

const MAX_N: Int64 = 1_000_000_000_000_000_000
const MAX_T = 8
const MAX_K = 8
const WIDTH = 9

fn is_prime(value: Int64) -> Bool:
    if value < 2: return False
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0: return False
        divisor += 1
    return True

fn stirling_value(n: Int64, k: Int, modulus: Int64) -> Int64:
    var matrix = InlineArray[Int64, WIDTH * WIDTH](fill=0)
    var squared = InlineArray[Int64, WIDTH * WIDTH](fill=0)
    var vector = InlineArray[Int64, WIDTH](fill=0)
    var next_vector = InlineArray[Int64, WIDTH](fill=0)
    let dimension = k + 1
    for index in range(dimension):
        matrix[index * WIDTH + index] = Int64(index) % modulus
        if index > 0:
            matrix[index * WIDTH + index - 1] = 1
    vector[0] = 1

    var exponent = n
    while exponent > 0:
        if exponent % 2 != 0:
            for row in range(dimension):
                var total: Int64 = 0
                for column in range(dimension):
                    total = (total + matrix[row * WIDTH + column] * vector[column]) % modulus
                next_vector[row] = total
            for row in range(dimension):
                vector[row] = next_vector[row]
        exponent //= 2
        if exponent > 0:
            for row in range(dimension):
                for column in range(dimension):
                    var total: Int64 = 0
                    for inner in range(dimension):
                        total = (total + matrix[row * WIDTH + inner] * matrix[inner * WIDTH + column]) % modulus
                    squared[row * WIDTH + column] = total
            for row in range(dimension):
                for column in range(dimension):
                    matrix[row * WIDTH + column] = squared[row * WIDTH + column]
                    squared[row * WIDTH + column] = 0
    return vector[k]

@export("stirling_number_of_the_second_kind_small_p_large_n")
fn stirling_number_of_the_second_kind_small_p_large_n(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(4) or length > c_size_t(18):
        return -1
    let count_value = input[0]
    let modulus = input[1]
    if count_value < 1 or count_value > MAX_T: return -1
    let count = Int(count_value)
    if length != c_size_t(2 + 2 * count): return -1
    if modulus < 11 or modulus > 97 or not is_prime(modulus): return -1

    var result: Int64 = 0
    for case_index in range(count):
        let n = input[2 + 2 * case_index]
        let k_value = input[3 + 2 * case_index]
        if n < 0 or n > MAX_N or k_value < 0 or k_value > MAX_K or k_value > n: return -1
        let k = Int(k_value)
        let value = stirling_value(n, k, modulus)
        let next = Int64(case_index + 1)
        result = (result + next * next * value) % modulus
    return result
