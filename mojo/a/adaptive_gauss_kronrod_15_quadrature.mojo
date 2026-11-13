from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import exp, fabs, isfinite, sin
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INTERVALS = 16
comptime MAX_INPUT_LENGTH = 6

fn exact_integer(value: Float64, low: Int, high: Int) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    return Float64(Int(value)) == value

fn sample(function_id: Int, x: Float64) -> Float64:
    if function_id == 0: return exp(4.0 * x)
    if function_id == 1: return sin(10.0 * x)
    if function_id == 2: return 1.0 / (1.0 + 9.0 * x * x)
    let x2 = x * x
    let x4 = x2 * x2
    let x8 = x4 * x4
    return x8 * x4 * x2

fn pair_estimate(function_id: Int, a: Float64, b: Float64) -> InlineArray[Float64, 2]:
    let nodes = InlineArray[Float64, 7](
        0.9914553711208126392, 0.9491079123427585245, 0.8648644233597690728,
        0.7415311855993944399, 0.5860872354676911303, 0.4058451513773971669,
        0.2077849550078984676)
    let kw = InlineArray[Float64, 7](
        0.022935322010529225, 0.06309209262997855, 0.10479001032225018,
        0.14065325971552592, 0.16900472663926790, 0.19035057806478541,
        0.20443294007529889)
    let gw = InlineArray[Float64, 3](
        0.12948496616886969, 0.27970539148927667, 0.38183005050511894)
    let center = (a + b) * 0.5
    let half = (b - a) * 0.5
    let fc = sample(function_id, center)
    var ksum = 0.2094821410847278280 * fc
    var gsum = 0.4179591836734693878 * fc
    for index in range(7):
        let offset = half * nodes[index]
        let pair = sample(function_id, center - offset) + sample(function_id, center + offset)
        ksum += kw[index] * pair
        if index == 1: gsum += gw[0] * pair
        if index == 3: gsum += gw[1] * pair
        if index == 5: gsum += gw[2] * pair
    var result = InlineArray[Float64, 2](fill=0.0)
    result[0] = half * ksum
    result[1] = half * gsum
    return result

fn compute(function_id: Int, a: Float64, b: Float64,
           tolerance: Float64, limit: Int) -> InlineArray[Float64, 2]:
    var answer = InlineArray[Float64, 2](fill=0.0)
    if a == b:
        answer[0] = 1.0
        return answer
    var lefts = InlineArray[Float64, MAX_INTERVALS](fill=0.0)
    var rights = InlineArray[Float64, MAX_INTERVALS](fill=0.0)
    var values = InlineArray[Float64, MAX_INTERVALS](fill=0.0)
    var errors = InlineArray[Float64, MAX_INTERVALS](fill=0.0)
    let initial = pair_estimate(function_id, a, b)
    lefts[0] = a
    rights[0] = b
    values[0] = initial[0]
    errors[0] = fabs(initial[0] - initial[1])
    var count = 1
    while True:
        var total = 0.0
        var error = 0.0
        for index in range(count):
            total += values[index]
            error += errors[index]
        if error <= tolerance * max(1.0, fabs(total)):
            if not isfinite(total): return answer
            answer[0] = 1.0
            answer[1] = total
            return answer
        if count >= limit: return answer
        var best = 0
        for index in range(1, count):
            if errors[index] > errors[best] or (errors[index] == errors[best] and lefts[index] < lefts[best]):
                best = index
        let l = lefts[best]
        let r = rights[best]
        let middle = (l + r) * 0.5
        let first = pair_estimate(function_id, l, middle)
        let second = pair_estimate(function_id, middle, r)
        lefts[best] = l
        rights[best] = middle
        values[best] = first[0]
        errors[best] = fabs(first[0] - first[1])
        lefts[count] = middle
        rights[count] = r
        values[count] = second[0]
        errors[count] = fabs(second[0] - second[1])
        count += 1

@export("adaptive_gauss_kronrod_15_quadrature")
fn adaptive_gauss_kronrod_15_quadrature(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length != 5 or input_length > MAX_INPUT_LENGTH: return -1
    let raw_id = input[0]
    let raw_a = input[1]
    let raw_b = input[2]
    let raw_exponent = input[3]
    let raw_limit = input[4]
    if not exact_integer(raw_id, 0, 3) or not exact_integer(raw_a, -1000000, 1000000) or not exact_integer(raw_b, -1000000, 1000000) or not exact_integer(raw_exponent, 6, 8) or not exact_integer(raw_limit, 1, MAX_INTERVALS): return -1
    if raw_a > raw_b: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < 1: return -2
    let id = Int(raw_id)
    let a = Float64(Int(raw_a)) / 1000000.0
    let b = Float64(Int(raw_b)) / 1000000.0
    let exponent = Int(raw_exponent)
    let limit = Int(raw_limit)
    var tolerance = 1.0
    for _ in range(exponent): tolerance *= 0.1
    let result = compute(id, a, b, tolerance, limit)
    if result[0] == 0.0: return -3
    if result[0] != 1.0 or not isfinite(result[1]): return -1
    output[0] = result[1]
    return 1
