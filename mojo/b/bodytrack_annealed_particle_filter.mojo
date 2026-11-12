from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_D = 4
comptime MAX_N = 16
comptime MAX_L = 4
comptime MAX_INPUT = 318
comptime Q24 = Int64(16_777_216)

fn round_away(numerator: Int64, denominator: Int64) -> Int64:
    let magnitude = if numerator < 0: -numerator else: numerator
    var quotient = magnitude // denominator
    let remainder = magnitude % denominator
    if 2 * remainder >= denominator: quotient += 1
    return if numerator < 0: -quotient else: quotient

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("bodytrack_annealed_particle_filter")
fn bodytrack_annealed_particle_filter(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT:
        return -1
    let d_value, n_value, layers_value = input[0], input[1], input[2]
    if d_value < 1 or d_value > MAX_D or n_value < 2 or n_value > MAX_N
            or layers_value < 1 or layers_value > MAX_L: return -1
    let d, n, layers = Int(d_value), Int(n_value), Int(layers_value)
    let expected = 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1)
    if length != c_size_t(expected): return -1

    let target_at = 3
    let beta_at = target_at + d
    let sigma_at = beta_at + layers
    let pose_at = sigma_at + layers - 1
    let uniform_at = pose_at + n * d
    let shock_at = uniform_at + (layers - 1) * n
    var target = InlineArray[Int64, MAX_D]()
    var beta = InlineArray[Int64, MAX_L]()
    var sigma = InlineArray[Int64, MAX_L - 1]()
    for axis in range(d):
        target[axis] = input[target_at + axis]
        if target[axis] < -10000 or target[axis] > 10000: return -1
    for layer in range(layers):
        beta[layer] = input[beta_at + layer]
        if beta[layer] < 1 or beta[layer] > 8: return -1
        if layer > 0 and beta[layer] <= beta[layer - 1]: return -1
    for layer in range(layers - 1):
        sigma[layer] = input[sigma_at + layer]
        if sigma[layer] < 0 or sigma[layer] > 2000: return -1
        if layer > 0 and sigma[layer] > sigma[layer - 1]: return -1
    for item in range(n * d):
        if input[pose_at + item] < -10000 or input[pose_at + item] > 10000: return -1
    for item in range((layers - 1) * n):
        if input[uniform_at + item] < 0 or input[uniform_at + item] >= Q24: return -1
    for item in range((layers - 1) * n * d):
        if input[shock_at + item] < -3000 or input[shock_at + item] > 3000: return -1

    let required = 8 * d
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var population = InlineArray[Int64, 2 * MAX_N * MAX_D]()
    var weights = InlineArray[Int64, MAX_N]()
    var estimate = InlineArray[Int64, MAX_D]()
    for particle in range(n):
        for axis in range(d):
            population[particle * MAX_D + axis] = input[pose_at + particle * d + axis]
    var active = 0
    for layer in range(layers):
        var total_weight: Int64 = 0
        for particle in range(n):
            var squared_distance: Int64 = 0
            for axis in range(d):
                let offset = active * MAX_N * MAX_D + particle * MAX_D + axis
                let delta = population[offset] - target[axis]
                squared_distance += delta * delta
            let energy = squared_distance // 10000
            let base = (Q24 * 100000) // (100000 + energy)
            var weight = base
            for power in range(1, Int(beta[layer])):
                weight = (weight * base) // Q24
            weights[particle] = weight
            total_weight += weight
        if layer + 1 == layers:
            for axis in range(d):
                var moment: Int64 = 0
                for particle in range(n):
                    let offset = active * MAX_N * MAX_D + particle * MAX_D + axis
                    moment += weights[particle] * population[offset]
                estimate[axis] = round_away(moment, total_weight)
            break
        let destination = 1 - active
        for child in range(n):
            let draw = input[uniform_at + layer * n + child]
            let threshold = (draw * total_weight) // Q24
            var cumulative: Int64 = 0
            var ancestor = 0
            while cumulative <= threshold:
                cumulative += weights[ancestor]
                ancestor += 1
            ancestor -= 1
            for axis in range(d):
                let shock_index = shock_at + layer * n * d + child * d + axis
                let movement = round_away(sigma[layer] * input[shock_index], 1000)
                let source = active * MAX_N * MAX_D + ancestor * MAX_D + axis
                let destination_offset = destination * MAX_N * MAX_D + child * MAX_D + axis
                let coordinate = population[source] + movement
                population[destination_offset] = max(-10000, min(10000, coordinate))
        active = destination
    for axis in range(d):
        store_i64_le(output, 8 * axis, estimate[axis])
    return Int64(required)
