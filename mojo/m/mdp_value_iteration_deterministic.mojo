from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mdp_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = bitcast[UInt64](value)
    for byte in range(8):
        output[slot * 8 + byte] = UInt8(bits & 255)
        bits >>= 8

@export("mdp_value_iteration_deterministic")
fn mdp_value_iteration_deterministic(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 29:
        return -1
    let states = input[0]
    let actions = input[1]
    let horizon = input[2]
    let p = input[3]
    let q = input[4]
    if states < 1 or states > 4 or actions < 1 or actions > 3 or horizon < 1 or horizon > 8 or q < 1 or q > 4 or p < 0 or p >= q:
        return -1
    let s = Int(states)
    let a = Int(actions)
    if length != c_size_t(5 + 2 * s * a):
        return -1
    var rewards = InlineArray[Int64, 12](fill=0)
    var targets = InlineArray[Int, 12](fill=0)
    for i in range(s * a):
        let reward = input[5 + 2 * i]
        let target = input[6 + 2 * i]
        if reward < -100 or reward > 100 or target < 0 or target >= states:
            return -1
        rewards[i] = reward
        targets[i] = Int(target)
    let bytes = 8 * (1 + 2 * s)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    var scale: Int64 = 1
    for _ in range(Int(horizon)):
        scale *= q
    var value = InlineArray[Int64, 4](fill=0)
    var updated = InlineArray[Int64, 4](fill=0)
    var policy = InlineArray[Int64, 4](fill=0)
    for _ in range(Int(horizon)):
        for state in range(s):
            let first = state * a
            var best = rewards[first] * scale + p * (value[targets[first]] // q)
            var best_action: Int64 = 0
            for action in range(1, a):
                let index = first + action
                let candidate = rewards[index] * scale + p * (value[targets[index]] // q)
                if candidate > best:
                    best = candidate
                    best_action = Int64(action)
            updated[state] = best
            policy[state] = best_action
        for state in range(s):
            value[state] = updated[state]
    mdp_store(output, 0, scale)
    for state in range(s):
        mdp_store(output, 1 + state, value[state])
        mdp_store(output, 1 + s + state, policy[state])
    return Int64(bytes)
