from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_N = 8
const MAX_ROUNDS = 8
const MAX_INPUT = 259

@export("freivalds_matrix_product_verification")
fn freivalds_matrix_product_verification(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n64 = input[0]
    let rounds64 = input[1]
    if n64 < 1 or n64 > MAX_N or rounds64 < 1 or rounds64 > MAX_ROUNDS: return -1
    let n = Int(n64)
    let rounds = Int(rounds64)
    let matrix_words = n * n
    if length != c_size_t(2 + 3 * matrix_words + rounds * n): return -1
    for word in range(2, 2 + 3 * matrix_words):
        if input[word] < -3 or input[word] > 3: return -1
    let signs_offset = 2 + 3 * matrix_words
    for word in range(signs_offset, Int(length)):
        if input[word] != -1 and input[word] != 1: return -1

    var bx = InlineArray[Int64, 8](fill=0)
    var abx = InlineArray[Int64, 8](fill=0)
    var cx = InlineArray[Int64, 8](fill=0)
    for round in range(rounds):
        for row in range(n):
            var sum: Int64 = 0
            for col in range(n):
                sum += input[2 + matrix_words + row * n + col] * input[signs_offset + round * n + col]
            bx[row] = sum
        for row in range(n):
            var left: Int64 = 0
            var right: Int64 = 0
            for col in range(n):
                left += input[2 + row * n + col] * bx[col]
                right += input[2 + 2 * matrix_words + row * n + col] * input[signs_offset + round * n + col]
            abx[row] = left
            cx[row] = right
        for row in range(n):
            if abx[row] != cx[row]: return 0
    return 1
