from std.ffi import c_size_t
from std.math import exp, isfinite, trunc
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_STATES = 8
comptime MAX_STEPS = 64
comptime MAX_INPUT = 140

fn metropolis_bounded_integer(value: Float64, minimum: Float64, maximum: Float64) -> Bool:
    return isfinite(value) and trunc(value) == value and value >= minimum and value <= maximum

@export("metropolis_mcmc")
fn metropolis_mcmc(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 4 or length > MAX_INPUT:
        return -1
    if not metropolis_bounded_integer(input[0], 1.0, Float64(MAX_STATES)) or
        not metropolis_bounded_integer(input[1], 0.0, Float64(MAX_STEPS)):
        return -1
    let states = Int(input[0])
    let steps = Int(input[1])
    if not metropolis_bounded_integer(input[2], 0.0, Float64(states - 1)) or
        not isfinite(input[3]) or input[3] < 0.001 or input[3] > 1000.0 or
        length != c_size_t(4 + states + 2 * steps):
        return -1
    for state in range(states):
        let energy = input[4 + state]
        if not isfinite(energy) or energy < -1_000_000.0 or energy > 1_000_000.0:
            return -1
    let proposal_start = 4 + states
    let uniform_start = proposal_start + steps
    for step in range(steps):
        if not metropolis_bounded_integer(input[proposal_start + step], 0.0, Float64(states - 1)):
            return -1
        let uniform = input[uniform_start + step]
        if not isfinite(uniform) or uniform < 0.0 or uniform >= 1.0:
            return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(steps + 1):
        return -2

    var current = Int(input[2])
    output[0] = Float64(current)
    for step in range(steps):
        let proposal = Int(input[proposal_start + step])
        let delta = (input[4 + proposal] - input[4 + current]) / input[3]
        if delta <= 0.0:
            current = proposal
        elif input[uniform_start + step] < exp(-delta):
            current = proposal
        output[step + 1] = Float64(current)
    return Int64(steps + 1)
