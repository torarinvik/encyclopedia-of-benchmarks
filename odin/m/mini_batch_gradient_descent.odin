package mini_batch_gradient_descent

import "core:c"
import "core:math"

MAX_SAMPLES :: 8
MAX_FEATURES :: 3
MAX_INPUT :: 101

@(export)
mini_batch_gradient_descent :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 5 || input_length > MAX_INPUT do return -1
    for i in 0..<4 {
        if !math.is_finite(input[i]) || math.trunc(input[i]) != input[i] do return -1
    }
    if input[0] < 1 || input[0] > MAX_SAMPLES || input[1] < 1 || input[1] > MAX_FEATURES do return -1
    samples, features := int(input[0]), int(input[1])
    if input[2] < 1 || input[2] > f64(samples) || input[3] < 0 || input[3] > 8 do return -1
    batch_size, epochs := int(input[2]), int(input[3])
    learning_rate := input[4]
    if !math.is_finite(learning_rate) || learning_rate < 0 || learning_rate > 0.25 do return -1
    matrix_start := 5
    targets_start := matrix_start + samples*features
    permutations_start := targets_start + samples
    if input_length != c.size_t(permutations_start + epochs*samples) do return -1

    matrix: [MAX_SAMPLES*MAX_FEATURES]f64
    targets: [MAX_SAMPLES]f64
    for i in 0..<samples*features {
        value := input[matrix_start+i]
        if !math.is_finite(value) || math.abs(value) > 10 do return -1
        matrix[i] = value
    }
    for i in 0..<samples {
        value := input[targets_start+i]
        if !math.is_finite(value) || math.abs(value) > 100 do return -1
        targets[i] = value
    }
    permutations: [64]int
    for epoch in 0..<epochs {
        seen: [MAX_SAMPLES]bool
        for position in 0..<samples {
            raw := input[permutations_start+epoch*samples+position]
            if !math.is_finite(raw) || math.trunc(raw) != raw || raw < 0 || raw >= f64(samples) do return -1
            sample := int(raw)
            if seen[sample] do return -1
            seen[sample] = true
            permutations[epoch*samples+position] = sample
        }
    }

    weights: [MAX_FEATURES]f64
    bias: f64 = 0
    for epoch in 0..<epochs {
        start := 0
        for start < samples {
            batch_length := min(batch_size, samples-start)
            errors: [MAX_SAMPLES]f64
            for position in 0..<batch_length {
                sample := permutations[epoch*samples+start+position]
                prediction: f64 = 0
                for feature in 0..<features {
                    prediction += matrix[sample*features+feature] * weights[feature]
                    if !math.is_finite(prediction) do return -1
                }
                prediction += bias
                error := prediction - targets[sample]
                if !math.is_finite(prediction) || !math.is_finite(error) do return -1
                errors[position] = error
            }
            for feature in 0..<features {
                gradient: f64 = 0
                for position in 0..<batch_length {
                    sample := permutations[epoch*samples+start+position]
                    gradient += matrix[sample*features+feature] * errors[position]
                    if !math.is_finite(gradient) do return -1
                }
                update := (learning_rate*gradient) / f64(batch_length)
                weights[feature] -= update
                if !math.is_finite(update) || !math.is_finite(weights[feature]) do return -1
            }
            error_sum: f64 = 0
            for position in 0..<batch_length {
                error_sum += errors[position]
                if !math.is_finite(error_sum) do return -1
            }
            mean_error := error_sum / f64(batch_length)
            bias_update := learning_rate * mean_error
            bias -= bias_update
            if !math.is_finite(mean_error) || !math.is_finite(bias_update) || !math.is_finite(bias) do return -1
            start += batch_length
        }
    }
    staged: [MAX_FEATURES+1]f64
    for feature in 0..<features { staged[feature] = weights[feature] }
    staged[features] = bias
    if output == nil || capacity < c.size_t(features+1) do return -2
    for i in 0..<features+1 { output[i] = staged[i] }
    return i64(features+1)
}
