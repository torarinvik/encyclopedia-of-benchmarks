package hjm_forward_path

import "core:c"
import "core:math"

MAX_STEPS :: 8
MAX_FACTORS :: 3

@(export)
hjm_forward_path :: proc "c" (input: [^]f64, input_length: c.size_t,
    output: [^]f64, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 7 || input_length > 54 do return -1
    if !math.is_finite(input[0]) || input[0] < 2 || input[0] > MAX_STEPS || math.trunc(input[0]) != input[0] do return -1
    if !math.is_finite(input[1]) || input[1] < 1 || input[1] > MAX_FACTORS || math.trunc(input[1]) != input[1] do return -1
    steps := int(input[0])
    factors := int(input[1])
    years := input[2]
    if years != 1.0 && years != 2.0 && years != 3.0 do return -1
    if input_length != c.size_t(3 + steps + 2*factors*(steps-1)) do return -1

    yields: [MAX_STEPS]f64
    vols: [MAX_FACTORS*(MAX_STEPS-1)]f64
    shocks: [(MAX_STEPS-1)*MAX_FACTORS]f64
    forwards: [MAX_STEPS]f64
    factor_drifts: [MAX_FACTORS*(MAX_STEPS-1)]f64
    total_drifts: [MAX_STEPS-1]f64
    path: [MAX_STEPS*MAX_STEPS]f64
    cursor := 3
    for maturity in 0..<steps {
        value := input[cursor]
        cursor += 1
        if !math.is_finite(value) || value < -0.05 || value > 0.20 do return -1
        yields[maturity] = value
    }
    for factor in 0..<factors {
        for maturity in 0..<steps-1 {
            value := input[cursor]
            cursor += 1
            if !math.is_finite(value) || value < 0 || value > 0.30 do return -1
            vols[factor*(MAX_STEPS-1)+maturity] = value
        }
    }
    for time in 0..<steps-1 {
        for factor in 0..<factors {
            value := input[cursor]
            cursor += 1
            if !math.is_finite(value) || value < -3 || value > 3 do return -1
            shocks[time*MAX_FACTORS+factor] = value
        }
    }

    dt := years/f64(steps)
    forwards[0] = yields[0]
    for maturity in 1..<steps {
        forwards[maturity] = f64(maturity+1)*yields[maturity] - f64(maturity)*yields[maturity-1]
    }
    for factor in 0..<factors {
        base := factor*(MAX_STEPS-1)
        factor_drifts[base] = 0.5*dt*vols[base]*vols[base]
        for maturity in 1..<steps-1 {
            drift: f64 = 0
            for prior in 0..<maturity { drift -= factor_drifts[base+prior] }
            prefix_volatility: f64 = 0
            for prior in 0..<maturity+1 { prefix_volatility += vols[base+prior] }
            drift += 0.5*dt*prefix_volatility*prefix_volatility
            factor_drifts[base+maturity] = drift
        }
    }
    for maturity in 0..<steps-1 {
        for factor in 0..<factors {
            total_drifts[maturity] += factor_drifts[factor*(MAX_STEPS-1)+maturity]
        }
    }
    for maturity in 0..<steps { path[maturity] = forwards[maturity] }
    root_dt := math.sqrt_f64(dt)
    for time in 1..<steps {
        for maturity in 0..<steps-time {
            total_shock: f64 = 0
            for factor in 0..<factors {
                total_shock += vols[factor*(MAX_STEPS-1)+maturity] * shocks[(time-1)*MAX_FACTORS+factor]
            }
            path[time*steps+maturity] = path[(time-1)*steps+maturity+1] + total_drifts[maturity]*dt + root_dt*total_shock
        }
    }
    needed := steps*steps
    if output == nil || output_capacity < c.size_t(needed) do return -2
    for index in 0..<needed { output[index] = path[index] }
    return i64(needed)
}
