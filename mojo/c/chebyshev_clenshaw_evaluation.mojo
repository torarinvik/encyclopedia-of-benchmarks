from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MODULUS: Int64 = 998244353
const MAX_DEGREE = 16
const MAX_PARSEABLE_LENGTH = 21

fn reduce_field(value: Int64) -> Int64:
    var reduced = value % MODULUS
    if reduced < 0:
        reduced += MODULUS
    return reduced

@export("chebyshev_clenshaw_evaluation")
fn chebyshev_clenshaw_evaluation(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                 length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let degree_value = input[0]
    if degree_value < 0 or degree_value > MAX_DEGREE:
        return -1
    let degree = Int(degree_value)
    if length != c_size_t(degree + 3):
        return -1
    let x = input[1]
    if x < 0 or x >= MODULUS:
        return -1
    for i in range(degree + 1):
        let coefficient = input[2 + i]
        if coefficient < 0 or coefficient >= MODULUS:
            return -1

    let twice_x = (2 * x) % MODULUS
    var next_one: Int64 = 0
    var next_two: Int64 = 0
    for offset in range(degree):
        let k = degree - offset
        let current = reduce_field(input[2 + k] + twice_x * next_one - next_two)
        next_two = next_one
        next_one = current
    return reduce_field(input[2] + x * next_one - next_two)
