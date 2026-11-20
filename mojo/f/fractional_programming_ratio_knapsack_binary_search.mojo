from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 12
comptime MAX_WEIGHT = 32
comptime MAX_PARSEABLE = 27
comptime SCALE: Int64 = 1_000_000
comptime MAX_SCALED_RATIO: Int64 = 1_000_000_000
comptime NEGATIVE_INFINITY: Int64 = -2_305_843_009_213_693_952

fn ratio_feasible(numerators: InlineArray[Int64, MAX_N],
                  denominators: InlineArray[Int64, MAX_N], n: Int,
                  required_weight: Int, threshold: Int64) -> Bool:
    var current = InlineArray[Int64, 33](fill=NEGATIVE_INFINITY)
    var next = InlineArray[Int64, 33](fill=NEGATIVE_INFINITY)
    current[0] = 0
    for item in range(n):
        for weight in range(required_weight + 1):
            next[weight] = current[weight]
        let score = SCALE * numerators[item] - threshold * denominators[item]
        for weight in range(required_weight + 1):
            if current[weight] != NEGATIVE_INFINITY:
                let sum_weight = weight + Int(denominators[item])
                let target = sum_weight if sum_weight < required_weight else required_weight
                let candidate = current[weight] + score
                if candidate > next[target]: next[target] = candidate
        for weight in range(required_weight + 1):
            current[weight] = next[weight]
    return current[required_weight] >= 0

@export("fractional_programming_ratio_knapsack_binary_search")
fn fractional_programming_ratio_knapsack_binary_search(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or
        length > c_size_t(MAX_PARSEABLE):
        return -1
    let n_value = input[0]
    let required_value = input[1]
    if n_value < 1 or n_value > MAX_N or required_value < 1 or required_value > MAX_WEIGHT:
        return -1
    let n = Int(n_value)
    let required_weight = Int(required_value)
    if length != c_size_t(2 + 2 * n): return -1

    var numerators = InlineArray[Int64, MAX_N](fill=0)
    var denominators = InlineArray[Int64, MAX_N](fill=0)
    var denominator_sum: Int64 = 0
    for item in range(n):
        let numerator = input[2 + 2 * item]
        let denominator = input[3 + 2 * item]
        if numerator < 0 or numerator > 1000 or denominator < 1 or denominator > 8:
            return -1
        numerators[item] = numerator
        denominators[item] = denominator
        denominator_sum += denominator
    if required_value > denominator_sum: return -1

    var low: Int64 = 0
    var high: Int64 = MAX_SCALED_RATIO + 1
    while high - low > 1:
        let middle = low + (high - low) // 2
        if ratio_feasible(numerators, denominators, n, required_weight, middle):
            low = middle
        else:
            high = middle
    return low
