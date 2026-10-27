package mdp_value_iteration_deterministic

import "core:c"

MAX_STATES :: 4
MAX_ACTIONS :: 3
MAX_INPUT :: 29
MAX_OUTPUT :: 72

put64 :: proc(output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
mdp_value_iteration_deterministic :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 7 || length > MAX_INPUT do return -1
    s64, a64, h64, p, q := input[0], input[1], input[2], input[3], input[4]
    if s64 < 1 || s64 > 4 || a64 < 1 || a64 > 3 || h64 < 1 || h64 > 8 || q < 1 || q > 4 || p < 0 || p >= q || length != c.size_t(5+2*s64*a64) do return -1
    states, actions, horizon := int(s64), int(a64), int(h64)
    rewards: [MAX_STATES][MAX_ACTIONS]i64
    targets: [MAX_STATES][MAX_ACTIONS]i64
    at := 5
    for s := 0; s < states; s += 1 {
        for a := 0; a < actions; a += 1 {
            reward, target := input[at], input[at+1]
            at += 2
            if reward < -100 || reward > 100 || target < 0 || target >= s64 do return -1
            rewards[s][a], targets[s][a] = reward, target
        }
    }
    scale: i64 = 1
    for step := 0; step < horizon; step += 1 { scale *= q }
    value: [MAX_STATES]i64
    next_value: [MAX_STATES]i64
    policy: [MAX_STATES]i64
    for step := 0; step < horizon; step += 1 {
        for s := 0; s < states; s += 1 {
            best: i64 = -9223372036854775807-1
            best_action := 0
            for a := 0; a < actions; a += 1 {
                candidate := rewards[s][a]*scale + p*(value[int(targets[s][a])] / q)
                if candidate > best { best, best_action = candidate, a }
            }
            next_value[s], policy[s] = best, i64(best_action)
        }
        for s := 0; s < states; s += 1 { value[s] = next_value[s] }
    }
    bytes := 8*(1+2*states)
    if output == nil || capacity < c.size_t(bytes) do return -2
    staged: [MAX_OUTPUT]u8
    put64(output, 0, scale)
    for s := 0; s < states; s += 1 { put64(output, 8*(1+s), value[s]) }
    for s := 0; s < states; s += 1 { put64(output, 8*(1+states+s), policy[s]) }
    return i64(bytes)
}
