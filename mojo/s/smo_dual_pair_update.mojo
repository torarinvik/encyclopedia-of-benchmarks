from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_D = 3
comptime MAX_INPUT = 47

fn valid_field(x: Float64, low: Int64, high: Int64) -> Bool:
    return isfinite(x) and x >= Float64(low) and x <= Float64(high) and Float64(Int64(x)) == x

fn pair_dot(x: InlineArray[Float64, MAX_N * MAX_D], a: Int, b: Int, d: Int) -> Float64:
    var sum: Float64 = 0.0
    for r in range(d): sum += x[a * MAX_D + r] * x[b * MAX_D + r]
    return sum

fn pair_objective(
    alpha: InlineArray[Float64, MAX_N], labels: InlineArray[Int64, MAX_N],
    x: InlineArray[Float64, MAX_N * MAX_D], n: Int, d: Int,
) -> Float64:
    var sum: Float64 = 0.0
    for p in range(n): sum += alpha[p]
    for p in range(n):
        for q in range(n):
            sum -= 0.5 * alpha[p] * alpha[q] * Float64(labels[p] * labels[q]) * pair_dot(x, p, q, d)
    return sum

@export("smo_dual_pair_update")
fn smo_dual_pair_update(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 6 or input_length > MAX_INPUT:
        return -1
    if not valid_field(input[0], 2, MAX_N) or not valid_field(input[1], 1, MAX_D) or
        not valid_field(input[2], 1, 5000) or not valid_field(input[3], -1000000, 1000000): return -1
    let n = Int(input[0])
    let d = Int(input[1])
    let c_milli = Int64(input[2])
    let b_milli = Int64(input[3])
    if input_length != c_size_t(6 + 2 * n + n * d): return -1

    var labels = InlineArray[Int64, MAX_N](fill=0)
    var alpha = InlineArray[Float64, MAX_N](fill=0.0)
    var features = InlineArray[Float64, MAX_N * MAX_D](fill=0.0)
    var negative = False
    var positive = False
    var equality: Int64 = 0
    var at = 4
    for k in range(n):
        if not valid_field(input[at], -1, 1) or input[at] == 0.0: return -1
        labels[k] = Int64(input[at])
        if labels[k] < 0: negative = True
        else: positive = True
        at += 1
    for k in range(n):
        if not valid_field(input[at], 0, c_milli): return -1
        let value = Int64(input[at])
        alpha[k] = Float64(value) / 1000.0
        equality += labels[k] * value
        at += 1
    if not negative or not positive or equality != 0: return -1
    for row in range(n):
        for col in range(d):
            if not valid_field(input[at], -32, 32): return -1
            features[row * MAX_D + col] = input[at]
            at += 1
    if not valid_field(input[at], 0, n - 1) or not valid_field(input[at + 1], 0, n - 1): return -1
    let i = Int(input[at])
    let j = Int(input[at + 1])
    if i == j: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(n + 1): return -2

    let c_value = Float64(c_milli) / 1000.0
    let bias = Float64(b_milli) / 1000.0
    let yi = labels[i]
    let yj = labels[j]
    let sign = yi * yj
    let old_i = alpha[i]
    let old_j = alpha[j]
    let kii = pair_dot(features, i, i, d)
    let kjj = pair_dot(features, j, j, d)
    let kij = pair_dot(features, i, j, d)
    var error_i = bias - Float64(yi)
    var error_j = bias - Float64(yj)
    for k in range(n):
        error_i += alpha[k] * Float64(labels[k]) * pair_dot(features, k, i, d)
        error_j += alpha[k] * Float64(labels[k]) * pair_dot(features, k, j, d)
    var low: Float64 = 0.0
    var high: Float64 = 0.0
    if yi != yj:
        low = max(0.0, old_j - old_i)
        high = min(c_value, c_value + old_j - old_i)
    else:
        low = max(0.0, old_i + old_j - c_value)
        high = min(c_value, old_i + old_j)
    let eta = 2.0 * kij - kii - kjj
    var new_j: Float64 = 0.0
    if eta < 0.0:
        new_j = max(low, min(high, old_j - Float64(yj) * (error_i - error_j) / eta))
    else:
        var candidate = alpha
        candidate[i] = old_i + Float64(sign) * (old_j - low)
        candidate[j] = low
        let low_score = pair_objective(candidate, labels, features, n, d)
        candidate[i] = old_i + Float64(sign) * (old_j - high)
        candidate[j] = high
        let high_score = pair_objective(candidate, labels, features, n, d)
        new_j = if high_score > low_score: high else: low
    let new_i = old_i + Float64(sign) * (old_j - new_j)
    let delta_i = new_i - old_i
    let delta_j = new_j - old_j
    let bias_i = bias - error_i - Float64(yi) * delta_i * kii - Float64(yj) * delta_j * kij
    let bias_j = bias - error_j - Float64(yi) * delta_i * kij - Float64(yj) * delta_j * kjj
    let new_bias = if new_i > 0.0 and new_i < c_value: bias_i
        elif new_j > 0.0 and new_j < c_value: bias_j
        else: 0.5 * (bias_i + bias_j)
    alpha[i] = new_i
    alpha[j] = new_j
    for k in range(n): output[k] = alpha[k]
    output[n] = new_bias
    return Int64(n + 1)
