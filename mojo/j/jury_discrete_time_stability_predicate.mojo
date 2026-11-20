from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

alias MAX_PARSEABLE_LENGTH = 7

@export("jury_discrete_time_stability_predicate")
fn jury_discrete_time_stability_predicate(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let degree = input[0]
    if degree < 1 or degree > 4 or length != c_size_t(degree + 2): return -1

    var coefficients = InlineArray[Int64, 5](fill=0)
    for index in range(Int(degree + 1)):
        let value = input[index + 1]
        if value < -9 or value > 9 or (index == 0 and value == 0): return -1
        coefficients[index] = value
    if coefficients[0] < 0:
        for index in range(Int(degree + 1)):
            coefficients[index] = -coefficients[index]

    var at_one: Int64 = 0
    var at_minus_one: Int64 = 0
    for index in range(Int(degree + 1)):
        at_one += coefficients[index]
        if (Int(degree) - index) % 2 == 0:
            at_minus_one += coefficients[index]
        else:
            at_minus_one -= coefficients[index]
    if at_one <= 0 or ((degree % 2 == 0 and at_minus_one <= 0) or (degree % 2 != 0 and at_minus_one >= 0)):
        return 0

    var row = InlineArray[Int64, 5](fill=0)
    var reduced = InlineArray[Int64, 5](fill=0)
    for index in range(Int(degree + 1)):
        row[index] = coefficients[index]
    for current_degree in range(Int(degree), 0, -1):
        let trailing = row[current_degree]
        let trailing_magnitude = if trailing < 0 then -trailing else trailing
        if row[0] <= trailing_magnitude: return 0
        if current_degree == 1: break
        for index in range(current_degree):
            reduced[index] = row[0] * row[index] - trailing * row[current_degree - index]
        for index in range(current_degree):
            row[index] = reduced[index]
    return 1
