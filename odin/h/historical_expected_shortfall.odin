package historical_expected_shortfall

import "core:c"
import "core:math"

@(export)
historical_expected_shortfall :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
    if input == nil || input_length < c.size_t(24) || input_length > c.size_t(69) do return -1
    for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
    portfolio_value, confidence_level, time_horizon, count_value := input[0], input[1], input[2], input[3]
    if count_value < 20 || count_value > 64 || math.trunc(count_value) != count_value do return -1
    return_count := int(count_value)
    if input_length != c.size_t(4 + return_count) || portfolio_value < 100 || portfolio_value > 1000000 ||
        confidence_level < 0.5 || confidence_level > 0.95 || time_horizon < 1 || time_horizon > 10 do return -1
    sorted_returns: [64]f64
    for i in 0..<return_count {
        value := input[4+i]
        if value < -0.25 || value > 0.25 do return -1
        position := i
        for position > 0 && sorted_returns[position-1] > value {
            sorted_returns[position] = sorted_returns[position-1]
            position -= 1
        }
        sorted_returns[position] = value
    }
    index := int(math.floor((1-confidence_level)*f64(return_count)))
    if index < 1 do return -1
    tail_sum: f64 = 0
    for i in 0..<index { tail_sum += sorted_returns[i] }
    result := -(tail_sum/f64(index)) * portfolio_value * math.sqrt(time_horizon)
    if output == nil || capacity < c.size_t(1) do return -2
    output[0] = result
    return 1
}
