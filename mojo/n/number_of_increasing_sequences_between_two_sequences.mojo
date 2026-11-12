from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_M = 64
alias MAX_INPUT_LENGTH = 130
alias MODULUS = 998244353

@export("number_of_increasing_sequences_between_two_sequences")
fn number_of_increasing_sequences_between_two_sequences(
    input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < c_size_t(4) or input_length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    if input[0] < 1 or input[0] > MAX_N or input[1] < 1 or input[1] > MAX_M:
        return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if input_length != c_size_t(2 + 2 * n):
        return -1
    var lower = InlineArray[Int64, MAX_N]()
    var upper = InlineArray[Int64, MAX_N]()
    for position in range(n):
        lower[position] = input[2 + position]
        upper[position] = input[2 + n + position]
        if lower[position] < 0 or lower[position] >= upper[position] or upper[position] > m:
            return -1

    var previous = InlineArray[Int64, MAX_M]()
    var current = InlineArray[Int64, MAX_M]()
    for value in range(Int(lower[0]), Int(upper[0])):
        previous[value] = 1
    for position in range(1, n):
        var prefix: Int64 = 0
        for value in range(m):
            prefix += previous[value]
            if prefix >= MODULUS:
                prefix -= MODULUS
            if lower[position] <= value and value < upper[position]:
                current[value] = prefix
            else:
                current[value] = 0
        for value in range(m):
            previous[value] = current[value]
    var answer: Int64 = 0
    for value in range(m):
        answer += previous[value]
        if answer >= MODULUS:
            answer -= MODULUS
    return answer
