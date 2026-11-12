"""Finite geometric power sum by binary composition of moment blocks."""
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MODULUS = Int64(998244353)
alias MAX_DEGREE = 32

fn sepm_shift(
    source: InlineArray[Int64, 33], shift: UInt64, degree: Int,
    choose: InlineArray[Int64, 1089],
) -> InlineArray[Int64, 33]:
    var powers = InlineArray[Int64, 33]()
    var destination = InlineArray[Int64, 33]()
    powers[0] = 1
    let reduced_shift = Int64(shift % UInt64(MODULUS))
    for i in range(1, degree + 1):
        powers[i] = powers[i - 1] * reduced_shift % MODULUS
    for d in range(degree + 1):
        var total: Int64 = 0
        for k in range(d + 1):
            let term = choose[d * 33 + k] * powers[d - k] % MODULUS
            total = (total + term * source[k]) % MODULUS
        destination[d] = total
    return destination

@export("sum_of_exponential_times_polynomial")
fn sum_of_exponential_times_polynomial(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3:
        return -1
    let r = input[0]
    let degree_value = input[1]
    let n_value = input[2]
    if r < 0 or r >= MODULUS or degree_value < 0 or degree_value > MAX_DEGREE or
        n_value < 0 or n_value > Int64(1000000000000000000):
        return -1
    let degree = Int(degree_value)
    var choose = InlineArray[Int64, 1089]()
    choose[0] = 1
    for d in range(1, degree + 1):
        choose[d * 33] = 1
        choose[d * 33 + d] = 1
        for k in range(1, d):
            choose[d * 33 + k] = (choose[(d - 1) * 33 + k - 1] + choose[(d - 1) * 33 + k]) % MODULUS

    var accumulated = InlineArray[Int64, 33]()
    var block = InlineArray[Int64, 33]()
    block[0] = 1
    var accumulated_power: Int64 = 1
    var block_power = r
    var accumulated_length: UInt64 = 0
    var block_length: UInt64 = 1
    var remaining = UInt64(n_value)
    while remaining > 0:
        if (remaining & UInt64(1)) != 0:
            let shifted = sepm_shift(block, accumulated_length, degree, choose)
            for d in range(degree + 1):
                accumulated[d] = (accumulated[d] + accumulated_power * shifted[d]) % MODULUS
            accumulated_power = accumulated_power * block_power % MODULUS
            accumulated_length += block_length
        let shifted_block = sepm_shift(block, block_length, degree, choose)
        for d in range(degree + 1):
            block[d] = (block[d] + block_power * shifted_block[d]) % MODULUS
        block_power = block_power * block_power % MODULUS
        block_length <<= 1
        remaining >>= 1
    return accumulated[degree]
