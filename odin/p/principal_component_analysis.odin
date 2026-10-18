package principal_component_analysis

import "core:c"
import "core:math"

MAX_SAMPLES :: 8
MAX_FEATURES :: 4
MAX_OUTPUT :: 34

@(export)
principal_component_analysis :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < 3 || input_length > 35 do return -1
    for i in 0..<3 {
        if !math.is_finite(input[i]) || math.trunc(input[i]) != input[i] do return -1
    }
    if input[0] < 2 || input[0] > 8 || input[1] < 2 || input[1] > 4 do return -1
    samples, features := int(input[0]), int(input[1])
    if input[2] < 1 || input[2] > f64(features) do return -1
    components := int(input[2])
    if input_length != c.size_t(3 + samples*features) do return -1

    means: [MAX_FEATURES]f64
    centered: [MAX_SAMPLES*MAX_FEATURES]f64
    for row in 0..<samples {
        for column in 0..<features {
            value := input[3+row*features+column]
            if !math.is_finite(value) || math.abs(value) > 100 do return -1
            means[column] += value
            if !math.is_finite(means[column]) do return -1
        }
    }
    for column in 0..<features {
        means[column] /= f64(samples)
        if !math.is_finite(means[column]) do return -1
    }
    for row in 0..<samples {
        for column in 0..<features {
            value := input[3+row*features+column] - means[column]
            if !math.is_finite(value) do return -1
            centered[row*features+column] = value
        }
    }

    matrix: [16]f64
    for i in 0..<features {
        for j in i..<features {
            covariance: f64 = 0
            for row in 0..<samples {
                covariance += centered[row*features+i] * centered[row*features+j]
                if !math.is_finite(covariance) do return -1
            }
            covariance /= f64(samples)
            if !math.is_finite(covariance) do return -1
            matrix[i*features+j] = covariance
            matrix[j*features+i] = covariance
        }
    }
    deflated := matrix
    eigenvectors: [16]f64
    for component in 0..<components {
        vector: [MAX_FEATURES]f64
        for i in 0..<features { vector[i] = 1 }
        converged := false
        for iteration in 0..<1000 {
            previous := vector
            next: [MAX_FEATURES]f64
            for i in 0..<features {
                for j in 0..<features {
                    next[i] += deflated[i*features+j] * vector[j]
                    if !math.is_finite(next[i]) do return -1
                }
            }
            norm_squared: f64 = 0
            for i in 0..<features {
                norm_squared += next[i]*next[i]
                if !math.is_finite(norm_squared) do return -1
            }
            norm := math.sqrt_f64(norm_squared)
            if !math.is_finite(norm) || norm <= 1e-10 do return -1
            for i in 0..<features {
                next[i] /= norm
                if !math.is_finite(next[i]) do return -1
            }
            difference: f64 = 0
            for i in 0..<features {
                change := math.abs(next[i] - previous[i])
                if !math.is_finite(change) do return -1
                if change > difference { difference = change }
            }
            vector = next
            if difference < 1e-10 {
                converged = true
                break
            }
        }
        if !converged do return -1
        numerator: f64 = 0
        for i in 0..<features {
            row_sum: f64 = 0
            for j in 0..<features {
                row_sum += deflated[i*features+j] * vector[j]
                if !math.is_finite(row_sum) do return -1
            }
            numerator += row_sum * vector[i]
            if !math.is_finite(numerator) do return -1
        }
        denominator: f64 = 0
        for i in 0..<features {
            denominator += vector[i]*vector[i]
            if !math.is_finite(denominator) do return -1
        }
        if denominator == 0 do return -1
        eigenvalue := numerator / denominator
        if !math.is_finite(eigenvalue) do return -1
        for i in 0..<features { eigenvectors[component*MAX_FEATURES+i] = vector[i] }
        for i in 0..<features {
            for j in 0..<features {
                deflated[i*features+j] -= eigenvalue * vector[i] * vector[j]
                if !math.is_finite(deflated[i*features+j]) do return -1
            }
        }
    }

    staged: [MAX_OUTPUT]f64
    staged[0], staged[1] = f64(samples), f64(components)
    for row in 0..<samples {
        for component in 0..<components {
            score: f64 = 0
            for column in 0..<features {
                score += eigenvectors[component*MAX_FEATURES+column] * centered[row*features+column]
                if !math.is_finite(score) do return -1
            }
            staged[2+row*components+component] = score
        }
    }
    output_size := 2 + samples*components
    if output == nil || capacity < c.size_t(output_size) do return -2
    for i in 0..<output_size { output[i] = staged[i] }
    return i64(output_size)
}
