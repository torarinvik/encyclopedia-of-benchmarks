from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MODULUS = 998244353
alias MAX_ORDER = 8
alias MAX_TERMS = 2 * MAX_ORDER
alias MAX_INPUT_VALUES = 1 + MAX_TERMS + 1

fn berlekamp_massey_normalize(value: Int64) -> Int64:
    let remainder = value % MODULUS
    return remainder + MODULUS if remainder < 0 else remainder

fn berlekamp_massey_multiply(left: Int64, right: Int64) -> Int64:
    return (left * right) % MODULUS

fn berlekamp_massey_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0:
            result = berlekamp_massey_multiply(result, base)
        base = berlekamp_massey_multiply(base, base)
        exponent >>= 1
    return result

fn berlekamp_massey_store(output: UnsafePointer[UInt8, MutAnyOrigin],
    offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn berlekamp_massey_infer(sequence: InlineArray[Int64, MAX_TERMS], term_count: Int,
    mut coefficients: InlineArray[Int64, MAX_TERMS + 1]) -> Int:
    var current = InlineArray[Int64, MAX_TERMS + 1]()
    var previous = InlineArray[Int64, MAX_TERMS + 1]()
    var old = InlineArray[Int64, MAX_TERMS + 1]()
    var current_length = 0
    var previous_length = 0
    var last_index = -1
    var last_discrepancy: Int64 = 0
    for index in range(term_count):
        var predicted: Int64 = 0
        for lag in range(min(current_length, index)):
            predicted = berlekamp_massey_normalize(predicted +
                berlekamp_massey_multiply(sequence[index - lag - 1], current[lag]))
        let discrepancy = berlekamp_massey_normalize(sequence[index] - predicted)
        if discrepancy == 0:
            continue

        if last_index < 0:
            last_index = index
            last_discrepancy = discrepancy
            current_length = index + 1
            for lag in range(current_length): current[lag] = 0
            continue

        for lag in range(current_length): old[lag] = current[lag]
        let old_length = current_length
        let shift = index - last_index
        let scale = berlekamp_massey_multiply(discrepancy,
            berlekamp_massey_power(last_discrepancy, MODULUS - 2))
        let needed_length = previous_length + shift
        if current_length < needed_length:
            for lag in range(current_length, needed_length): current[lag] = 0
            current_length = needed_length
        current[shift - 1] = berlekamp_massey_normalize(current[shift - 1] + scale)
        for lag in range(previous_length):
            current[shift + lag] = berlekamp_massey_normalize(
                current[shift + lag] - berlekamp_massey_multiply(scale, previous[lag]))

        if old_length - index < previous_length - last_index:
            for lag in range(old_length): previous[lag] = old[lag]
            previous_length = old_length
            last_index = index
            last_discrepancy = discrepancy
    for lag in range(current_length): coefficients[lag] = current[lag]
    return current_length

@export("berlekamp_massey")
fn berlekamp_massey(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_VALUES:
        return -1
    let bound_value = input[0]
    if bound_value < 1 or bound_value > MAX_ORDER:
        return -1
    let bound = Int(bound_value)
    let term_count = 2 * bound
    if length != c_size_t(1 + term_count):
        return -1

    var sequence = InlineArray[Int64, MAX_TERMS]()
    for index in range(term_count):
        let value = input[1 + index]
        if value < 0 or value >= MODULUS:
            return -1
        sequence[index] = value
    var coefficients = InlineArray[Int64, MAX_TERMS + 1]()
    let order = berlekamp_massey_infer(sequence, term_count, mut coefficients)
    if order > bound:
        return -1

    let output_bytes = 8 * (order + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    berlekamp_massey_store(output, 0, Int64(order))
    for lag in range(order):
        berlekamp_massey_store(output, 8 * (lag + 1), coefficients[lag])
    return Int64(output_bytes)
