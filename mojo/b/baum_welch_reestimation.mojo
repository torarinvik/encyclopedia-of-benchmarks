from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import abs, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_INPUT = 48
comptime MIN_PROBABILITY = 0.001
comptime ROW_TOLERANCE = 1e-9

fn exact_integer(value: Float64, low: Int64, high: Int64) -> Bool:
    if not isfinite(value) or value < Float64(low) or value > Float64(high): return False
    Float64(Int64(value)) == value

@export("baum_welch_reestimation")
fn baum_welch_reestimation(input: UnsafePointer[Float64, ImmutAnyOrigin], input_length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or input_length < 3 or input_length > MAX_INPUT:
        return -1
    if not exact_integer(input[0], 2, 4) or not exact_integer(input[1], 2, 4) or not exact_integer(input[2], 1, 8):
        return -1
    let states = Int(input[0])
    let symbols = Int(input[1])
    let time_count = Int(input[2])
    if input_length != c_size_t(3 + states + states * states + states * symbols + time_count): return -1

    var initial = InlineArray[Float64, 4]()
    var transition = InlineArray[Float64, 16]()
    var emission = InlineArray[Float64, 16]()
    var observations = InlineArray[Int, 8]()
    var cursor = 3
    for i in range(states): initial[i] = input[cursor + i]
    cursor += states
    for i in range(states * states): transition[i] = input[cursor + i]
    cursor += states * states
    for i in range(states * symbols): emission[i] = input[cursor + i]
    cursor += states * symbols
    var total = 0.0
    for i in range(states):
        if not isfinite(initial[i]) or initial[i] < MIN_PROBABILITY or initial[i] > 1.0: return -1
        total += initial[i]
    if abs(total - 1.0) > ROW_TOLERANCE: return -1
    for state in range(states):
        total = 0.0
        for j in range(states):
            let value = transition[state * states + j]
            if not isfinite(value) or value < MIN_PROBABILITY or value > 1.0: return -1
            total += value
        if abs(total - 1.0) > ROW_TOLERANCE: return -1
        total = 0.0
        for symbol in range(symbols):
            let value = emission[state * symbols + symbol]
            if not isfinite(value) or value < MIN_PROBABILITY or value > 1.0: return -1
            total += value
        if abs(total - 1.0) > ROW_TOLERANCE: return -1
    for time in range(time_count):
        if not exact_integer(input[cursor + time], 0, Int64(symbols - 1)): return -1
        observations[time] = Int(input[cursor + time])

    var alpha = InlineArray[Float64, 32]()
    var beta = InlineArray[Float64, 32]()
    var gamma = InlineArray[Float64, 32]()
    var staged = InlineArray[Float64, 36]()
    for state in range(states): alpha[state] = initial[state] * emission[state * symbols + observations[0]]
    for time in range(1, time_count):
        for destination in range(states):
            var incoming = 0.0
            for source in range(states): incoming += alpha[(time - 1) * states + source] * transition[source * states + destination]
            alpha[time * states + destination] = incoming * emission[destination * symbols + observations[time]]
    var likelihood = 0.0
    for state in range(states): likelihood += alpha[(time_count - 1) * states + state]
    for state in range(states): beta[(time_count - 1) * states + state] = 1.0
    for time in range(time_count - 1):
        let current = time_count - 2 - time
        for source in range(states):
            var sum = 0.0
            for destination in range(states):
                sum += transition[source * states + destination] * emission[destination * symbols + observations[current + 1]] * beta[(current + 1) * states + destination]
            beta[current * states + source] = sum
    for time in range(time_count):
        for state in range(states): gamma[time * states + state] = alpha[time * states + state] * beta[time * states + state] / likelihood

    let output_count = states + states * states + states * symbols
    var out = 0
    for state in range(states):
        staged[out] = gamma[state]
        out += 1
    if time_count == 1:
        for i in range(states * states):
            staged[out] = transition[i]
            out += 1
    else:
        for source in range(states):
            var denominator = 0.0
            for time in range(time_count - 1): denominator += gamma[time * states + source]
            for destination in range(states):
                var count = 0.0
                for time in range(time_count - 1):
                    count += alpha[time * states + source] * transition[source * states + destination] * emission[destination * symbols + observations[time + 1]] * beta[(time + 1) * states + destination] / likelihood
                staged[out] = count / denominator
                out += 1
    for state in range(states):
        var denominator = 0.0
        for time in range(time_count): denominator += gamma[time * states + state]
        for symbol in range(symbols):
            var count = 0.0
            for time in range(time_count):
                if observations[time] == symbol: count += gamma[time * states + state]
            staged[out] = count / denominator
            out += 1
    if out != output_count: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or output_capacity < c_size_t(output_count): return -2
    for i in range(output_count): output[i] = staged[i]
    Int64(output_count)
