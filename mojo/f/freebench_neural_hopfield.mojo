from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import exp
from std.memory import ImmutAnyOrigin, UnsafePointer

fn hopfield_recall(weights: InlineArray[Float32, 64], source: InlineArray[Int64, 80],
                   base: Int, n: Int, inout recalled: InlineArray[Int64, 8]) -> Bool:
    var activation = InlineArray[Float32, 8](fill=0.0)
    var next = InlineArray[Int64, 8](fill=0)
    for i in range(n): recalled[i] = source[base + i]
    var threshold = False
    var iterations = 0
    var stable = False
    while not stable and iterations < 500:
        for row in range(n):
            var field: Float32 = 0.0
            for col in range(n): field += weights[row * n + col] * Float32(source[base + col])
            let x = max(Float64(-200.0), min(Float64(200.0), Float64(field)))
            let e = exp(-x)
            activation[row] = Float32((1.0 - e) / (1.0 + e))
        var threshold_iterations = 0
        while not threshold and threshold_iterations < 50:
            threshold = True
            for row in range(n):
                if abs(activation[row]) < Float32(0.7):
                    var field: Float32 = 0.0
                    for col in range(n): field += weights[row * n + col] * activation[col]
                    let x = max(Float64(-200.0), min(Float64(200.0), Float64(field)))
                    let e = exp(-x)
                    activation[row] = Float32((1.0 - e) / (1.0 + e))
                    if activation[row] < Float32(0.7): threshold = False
            threshold_iterations += 1
        stable = True
        for i in range(n):
            next[i] = if activation[i] > 0.0: 1 else: -1
            if recalled[i] != next[i]: stable = False
        if not stable:
            for i in range(n):
                if recalled[i] != next[i]:
                    recalled[i] = next[i]
                    break
            for i in range(n): activation[i] = Float32(recalled[i])
        iterations += 1
    return iterations < 500

@export("freebench_neural_hopfield")
fn freebench_neural_hopfield(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 94: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8 or input[2] != 10: return -1
    let n = Int(input[0] * input[1])
    if n < 2 or n > 8 or Int(length) != 3 + 10 * (1 + n): return -1
    var patterns = InlineArray[Int64, 80](fill=0)
    var cursor = 3
    for pattern in range(10):
        if input[cursor] < 65 or input[cursor] > 90: return -1
        cursor += 1
        for neuron in range(n):
            let cell = input[cursor]
            cursor += 1
            if cell != -1 and cell != 1: return -1
            if pattern != 0 and cell != patterns[neuron]: return -1
            patterns[pattern * 8 + neuron] = cell
    var weights = InlineArray[Float32, 64](fill=0.0)
    for pattern in range(10):
        for row in range(n):
            for col in range(n):
                if row == col: weights[row * n + col] = 0.0
                else: weights[row * n + col] += Float32(patterns[pattern * 8 + row] * patterns[pattern * 8 + col])
    var converged = True
    for pattern in range(10):
        let base = pattern * 8
        var recalled = InlineArray[Int64, 8](fill=0)
        if not hopfield_recall(weights, patterns, base, n, recalled): return -2
        var correction = InlineArray[Float32, 8](fill=0.0)
        for row in range(n):
            correction[row] = Float32(patterns[base + row] - recalled[row]) * Float32(0.5)
            if correction[row] != 0.0: converged = False
        for row in range(n):
            for col in range(n):
                if row == col: weights[row * n + col] = 0.0
                else: weights[row * n + col] += correction[row] * Float32(patterns[base + col])
    if not converged: return -2
    var stored: Int64 = 0
    for pattern in range(10):
        let base = pattern * 8
        var recalled = InlineArray[Int64, 8](fill=0)
        if not hopfield_recall(weights, patterns, base, n, recalled): return -2
        var equal = True
        for i in range(n):
            if recalled[i] != patterns[base + i]: equal = False
        if equal: stored += 1
    return stored
