from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 12
comptime MAX_INPUT = 26
comptime MAX_PARSEABLE = 27

fn dfr_gcd(left: Int64, right: Int64) -> Int64:
    var a = left
    var b = right
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

fn dfr_before(a: Int, b: Int, scores: InlineArray[Int64, MAX_N]) -> Bool:
    if scores[a] != scores[b]: return scores[a] > scores[b]
    return a < b

@export("dinkelbach_fixed_cardinality_ratio")
fn dinkelbach_fixed_cardinality_ratio(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_PARSEABLE):
        return -1
    let n_value = input[0]
    let k_value = input[1]
    if n_value < 1 or n_value > MAX_N or k_value < 1 or k_value > n_value: return -1
    let n = Int(n_value)
    let k = Int(k_value)
    if length != c_size_t(2 + 2 * n) or length > c_size_t(MAX_INPUT): return -1

    var numerators = InlineArray[Int64, MAX_N](fill=0)
    var denominators = InlineArray[Int64, MAX_N](fill=0)
    for index in range(n):
        let a_value = input[2 + 2 * index]
        let b_value = input[3 + 2 * index]
        if a_value < 0 or a_value > 10_000 or b_value < 1 or b_value > 10_000: return -1
        numerators[index] = a_value
        denominators[index] = b_value

    var combination_count = 1
    for step in range(k): combination_count = combination_count * (n - step) // (step + 1)
    var ratio_numerator: Int64 = 0
    var ratio_denominator: Int64 = 1
    for _iteration in range(combination_count + 1):
        var scores = InlineArray[Int64, MAX_N](fill=0)
        var order = InlineArray[Int, MAX_N](fill=0)
        for index in range(n):
            scores[index] = numerators[index] * ratio_denominator - ratio_numerator * denominators[index]
            order[index] = index
        for index in range(1, n):
            let item = order[index]
            var position = index
            while position > 0 and dfr_before(item, order[position - 1], scores):
                order[position] = order[position - 1]
                position -= 1
            order[position] = item

        var selected_numerator: Int64 = 0
        var selected_denominator: Int64 = 0
        for index in range(k):
            selected_numerator += numerators[order[index]]
            selected_denominator += denominators[order[index]]
        let residual = selected_numerator * ratio_denominator - ratio_numerator * selected_denominator
        if residual == 0:
            let divisor = dfr_gcd(selected_numerator, selected_denominator)
            return (selected_numerator // divisor) * 120_001 + selected_denominator // divisor
        if residual < 0: return -1
        let divisor = dfr_gcd(selected_numerator, selected_denominator)
        ratio_numerator = selected_numerator // divisor
        ratio_denominator = selected_denominator // divisor
    return -1
