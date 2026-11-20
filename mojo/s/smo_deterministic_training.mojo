from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_D = 3
comptime MAX_INPUT = 37
comptime MAX_OUTPUT = 12
comptime TOLERANCE = 0.001
comptime EPSILON = 0.001

fn valid_field(value: Float64, low: Int64, high: Int64) -> Bool:
    return isfinite(value) and value >= Float64(low) and value <= Float64(high) and Float64(Int64(value)) == value

fn smo_kernel(points: InlineArray[Float64, MAX_N * MAX_D], i: Int, j: Int, d: Int) -> Float64:
    var sum: Float64 = 0.0
    for k in range(d): sum += points[i * MAX_D + k] * points[j * MAX_D + k]
    return sum

fn smo_decision(index: Int, alpha: InlineArray[Float64, MAX_N], bias: Float64,
    labels: InlineArray[Int64, MAX_N], points: InlineArray[Float64, MAX_N * MAX_D],
    n: Int, d: Int) -> Float64:
    var value = bias
    for k in range(n): value += alpha[k] * Float64(labels[k]) * smo_kernel(points, k, index, d)
    return value

fn smo_dual(alpha: InlineArray[Float64, MAX_N], labels: InlineArray[Int64, MAX_N],
    points: InlineArray[Float64, MAX_N * MAX_D], n: Int, d: Int) -> Float64:
    var value: Float64 = 0.0
    for i in range(n): value += alpha[i]
    for i in range(n):
        for j in range(n):
            value -= 0.5 * alpha[i] * alpha[j] * Float64(labels[i] * labels[j]) * smo_kernel(points, i, j, d)
    return value

fn smo_take_step(i: Int, j: Int, inout alpha: InlineArray[Float64, MAX_N],
    inout bias: Float64, c: Float64, labels: InlineArray[Int64, MAX_N],
    points: InlineArray[Float64, MAX_N * MAX_D], n: Int, d: Int) -> Bool:
    if i == j: return False
    let yi = labels[i]
    let yj = labels[j]
    let sign = yi * yj
    let old_i = alpha[i]
    let old_j = alpha[j]
    let error_i = smo_decision(i, alpha, bias, labels, points, n, d) - Float64(yi)
    let error_j = smo_decision(j, alpha, bias, labels, points, n, d) - Float64(yj)
    var low: Float64 = 0.0
    var high: Float64 = 0.0
    if yi != yj:
        low = max(0.0, old_j - old_i)
        high = min(c, c + old_j - old_i)
    else:
        low = max(0.0, old_i + old_j - c)
        high = min(c, old_i + old_j)
    if low == high: return False
    let kii = smo_kernel(points, i, i, d)
    let kjj = smo_kernel(points, j, j, d)
    let kij = smo_kernel(points, i, j, d)
    let curvature = kii + kjj - 2.0 * kij
    var next_j: Float64 = 0.0
    if curvature > 0.0:
        next_j = max(low, min(high, old_j + Float64(yj) * (error_i - error_j) / curvature))
    else:
        var trial = alpha
        trial[i] = old_i + Float64(sign) * (old_j - low)
        trial[j] = low
        let low_score = smo_dual(trial, labels, points, n, d)
        trial[i] = old_i + Float64(sign) * (old_j - high)
        trial[j] = high
        let high_score = smo_dual(trial, labels, points, n, d)
        if low_score > high_score + EPSILON: next_j = low
        elif high_score > low_score + EPSILON: next_j = high
        else: next_j = old_j
    if abs(next_j - old_j) < EPSILON * (next_j + old_j + EPSILON): return False
    let next_i = old_i + Float64(sign) * (old_j - next_j)
    let di = next_i - old_i
    let dj = next_j - old_j
    let bias_i = bias - error_i - Float64(yi) * di * kii - Float64(yj) * dj * kij
    let bias_j = bias - error_j - Float64(yi) * di * kij - Float64(yj) * dj * kjj
    if next_i > 0.0 and next_i < c: bias = bias_i
    elif next_j > 0.0 and next_j < c: bias = bias_j
    else: bias = 0.5 * (bias_i + bias_j)
    alpha[i] = next_i
    alpha[j] = next_j
    return True

fn smo_examine(j: Int, inout alpha: InlineArray[Float64, MAX_N], inout bias: Float64,
    c: Float64, labels: InlineArray[Int64, MAX_N], points: InlineArray[Float64, MAX_N * MAX_D],
    n: Int, d: Int) -> Bool:
    let error_j = smo_decision(j, alpha, bias, labels, points, n, d) - Float64(labels[j])
    let residual = error_j * Float64(labels[j])
    if not ((residual < -TOLERANCE and alpha[j] < c) or
            (residual > TOLERANCE and alpha[j] > 0.0)): return False
    var free_count = 0
    var preferred = 0
    var greatest_gap: Float64 = -1.0
    for i in range(n):
        if alpha[i] > 0.0 and alpha[i] < c:
            free_count += 1
            let error_i = smo_decision(i, alpha, bias, labels, points, n, d) - Float64(labels[i])
            let gap = abs(error_i - error_j)
            if gap > greatest_gap:
                greatest_gap = gap
                preferred = i
    if free_count > 1 and smo_take_step(preferred, j, alpha, bias, c, labels, points, n, d): return True
    for i in range(n):
        if alpha[i] > 0.0 and alpha[i] < c and smo_take_step(i, j, alpha, bias, c, labels, points, n, d):
            return True
    for i in range(n):
        if smo_take_step(i, j, alpha, bias, c, labels, points, n, d): return True
    return False

@export("smo_deterministic_training")
fn smo_deterministic_training(
    input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 4 or input_length > MAX_INPUT:
        return -1
    if not valid_field(input[0], 2, MAX_N) or not valid_field(input[1], 1, MAX_D) or
        not valid_field(input[2], 1, 5000) or not valid_field(input[3], 1, 16): return -1
    let n = Int(input[0])
    let d = Int(input[1])
    let c_milli = Int64(input[2])
    let pass_cap = Int(input[3])
    if input_length != c_size_t(4 + n + n * d): return -1
    var labels = InlineArray[Int64, MAX_N](fill=0)
    var alpha = InlineArray[Float64, MAX_N](fill=0.0)
    var points = InlineArray[Float64, MAX_N * MAX_D](fill=0.0)
    var positive = False
    var negative = False
    var at = 4
    for i in range(n):
        if not valid_field(input[at], -1, 1) or input[at] == 0.0: return -1
        labels[i] = Int64(input[at])
        if labels[i] > 0: positive = True
        else: negative = True
        at += 1
    if not positive or not negative: return -1
    for i in range(n):
        for k in range(d):
            if not valid_field(input[at], -32, 32): return -1
            points[i * MAX_D + k] = input[at]
            at += 1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(n + 4): return -2

    let c = Float64(c_milli) / 1000.0
    var bias: Float64 = 0.0
    var changed = 0
    var passes = 0
    var examine_all = True
    while passes < pass_cap and (changed > 0 or examine_all):
        changed = 0
        for j in range(n):
            if (examine_all or (alpha[j] > 0.0 and alpha[j] < c)) and
                smo_examine(j, alpha, bias, c, labels, points, n, d): changed += 1
        passes += 1
        if examine_all: examine_all = False
        elif changed == 0: examine_all = True
    var staged = InlineArray[Float64, MAX_OUTPUT](fill=0.0)
    staged[0] = Float64(passes)
    staged[1] = Float64(changed)
    staged[2] = if passes < pass_cap and changed == 0 and not examine_all: 1.0 else: 0.0
    for i in range(n): staged[3 + i] = alpha[i]
    staged[3 + n] = bias
    for i in range(n + 4): output[i] = staged[i]
    return Int64(n + 4)
