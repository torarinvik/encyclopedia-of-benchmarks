from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List
from std.math import exp, log

fn anova_abs(x: Float64) -> Float64:
    if x < 0.0: return -x
    return x

fn anova_safe_denominator(x: Float64) -> Float64:
    if anova_abs(x) >= 1.0e-300: return x
    if x < 0.0: return -1.0e-300
    return 1.0e-300

fn anova_lgamma(value: Float64) -> Float64:
    let z = value - 1.0
    var sum = 0.99999999999980993
    sum += 676.5203681218851 / (z + 1.0)
    sum += -1259.1392167224028 / (z + 2.0)
    sum += 771.32342877765313 / (z + 3.0)
    sum += -176.61502916214059 / (z + 4.0)
    sum += 12.507343278686905 / (z + 5.0)
    sum += -0.13857109526572012 / (z + 6.0)
    sum += 9.9843695780195716e-6 / (z + 7.0)
    sum += 1.5056327351493116e-7 / (z + 8.0)
    let t = z + 7.5
    return 0.91893853320467274178 + (z + 0.5) * log(t) - t + log(sum)

fn anova_beta_fraction(a: Float64, b: Float64, x: Float64) -> Float64:
    let qab = a + b
    let qap = a + 1.0
    let qam = a - 1.0
    var c: Float64 = 1.0
    var d = anova_safe_denominator(1.0 - qab * x / qap)
    d = 1.0 / d
    var result = d
    for m in range(1, 201):
        let mv = Float64(m)
        let m2 = 2.0 * mv
        var coefficient = mv * (b - mv) * x / ((qam + m2) * (a + m2))
        d = anova_safe_denominator(1.0 + coefficient * d)
        c = anova_safe_denominator(1.0 + coefficient / c)
        d = 1.0 / d
        result *= d * c
        coefficient = -(a + mv) * (qab + mv) * x / ((a + m2) * (qap + m2))
        d = anova_safe_denominator(1.0 + coefficient * d)
        c = anova_safe_denominator(1.0 + coefficient / c)
        d = 1.0 / d
        let change = d * c
        result *= change
        if anova_abs(change - 1.0) <= 3.0e-14: break
    return result

fn anova_regularized_beta(x: Float64, a: Float64, b: Float64) -> Float64:
    if x <= 0.0: return 0.0
    if x >= 1.0: return 1.0
    let front = exp(a * log(x) + b * log(1.0 - x) + anova_lgamma(a + b) - anova_lgamma(a) - anova_lgamma(b))
    if x < (a + 1.0) / (a + b + 2.0):
        return front * anova_beta_fraction(a, b, x) / a
    return 1.0 - front * anova_beta_fraction(b, a, 1.0 - x) / b

@export("anova_oneway")
fn anova_oneway(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    let invalid = -1.0e300
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return invalid
    let stat = input[0]
    let n = input[1]
    let k = input[2]
    if stat < 0 or stat > 7 or n <= k or n > 128 or k < 2 or k > 8 or length != c_size_t(3 + 2 * n): return invalid
    var group_sums = List[Float64](length=8, fill=0.0)
    var group_means = List[Float64](length=8, fill=0.0)
    var group_sizes = List[Int64](length=8, fill=0)
    var labels = List[Int64](length=128, fill=0)
    var total: Float64 = 0.0
    for i in range(n):
        let value = input[3 + i]
        let group = input[3 + n + i]
        if value < -1000000 or value > 1000000 or group < 0 or group >= k: return invalid
        labels[Int(i)] = group
        group_sums[Int(group)] += Float64(value)
        group_sizes[Int(group)] += 1
        total += Float64(value)
    for group in range(k):
        if group_sizes[group] == 0: return invalid
        group_means[group] = group_sums[group] / Float64(group_sizes[group])
    let grand = total / Float64(n)
    var ss_between: Float64 = 0.0
    for group in range(k):
        let diff = group_means[group] - grand
        ss_between += Float64(group_sizes[group]) * diff * diff
    var ss_within: Float64 = 0.0
    for group in range(k):
        for i in range(n):
            if labels[Int(i)] == Int64(group):
                let diff = Float64(input[3 + i]) - group_means[group]
                ss_within += diff * diff
    if not (ss_within > 0.0): return invalid
    let df_between = Float64(k - 1)
    let df_within = Float64(n - k)
    let ms_between = ss_between / df_between
    let ms_within = ss_within / df_within
    let f = ms_between / ms_within
    let beta_x = df_within / (df_within + df_between * f)
    let p = anova_regularized_beta(beta_x, df_within / 2.0, df_between / 2.0)
    if stat == 0: return df_between
    if stat == 1: return df_within
    if stat == 2: return ss_between
    if stat == 3: return ss_within
    if stat == 4: return ms_between
    if stat == 5: return ms_within
    if stat == 6: return f
    return p
