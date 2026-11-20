from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_STATES = 4
comptime MAX_ACTIONS = 3
comptime MAX_RECORDS = 12
comptime MAX_OUTPUT_WORDS = 13

@fieldwise_init
struct Fraction(Copyable):
    var numerator: Int64
    var denominator: Int64

@fieldwise_init
struct PolicyContext:
    var rewards: InlineArray[Int64, MAX_RECORDS]
    var successors: InlineArray[Int64, MAX_RECORDS]
    var policy: InlineArray[Int, MAX_STATES]
    var values: InlineArray[Fraction, MAX_STATES]

fn gcd_u64(a_value: UInt64, b_value: UInt64) -> UInt64:
    var a = a_value
    var b = b_value
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

fn reduce_fraction(numerator: Int64, denominator: Int64) -> Fraction:
    let magnitude = UInt64(-numerator) if numerator < 0 else UInt64(numerator)
    let divisor = gcd_u64(magnitude, UInt64(denominator))
    return Fraction(numerator=numerator // Int64(divisor), denominator=denominator // Int64(divisor))

fn power_i64(base: Int64, exponent_value: Int) -> Int64:
    var result: Int64 = 1
    var exponent = exponent_value
    while exponent > 0:
        result *= base
        exponent -= 1
    return result

fn extend_value(reward: Int64, successor: Fraction, p: Int64, q: Int64) -> Fraction:
    return reduce_fraction(reward * successor.denominator * q + p * successor.numerator,
                           successor.denominator * q)

fn evaluate_policy(mut context: PolicyContext, states: Int, actions: Int, p: Int64, q: Int64):
    for start in range(states):
        var first_seen = InlineArray[Int, MAX_STATES](fill=-1)
        var path = InlineArray[Int, MAX_STATES](fill=0)
        var path_length = 0
        var current = start
        while first_seen[current] < 0:
            first_seen[current] = path_length
            path[path_length] = current
            path_length += 1
            let state = path[path_length - 1]
            let record = state * actions + context.policy[state]
            current = Int(context.successors[record])
        let cycle_start = first_seen[current]
        let cycle_length = path_length - cycle_start
        var cycle_numerator: Int64 = 0
        for j in range(cycle_length):
            let state = path[cycle_start + j]
            let record = state * actions + context.policy[state]
            cycle_numerator += context.rewards[record] * power_i64(p, j) * power_i64(q, cycle_length - j)
        let cycle_denominator = power_i64(q, cycle_length) - power_i64(p, cycle_length)
        context.values[path[cycle_start]] = reduce_fraction(cycle_numerator, cycle_denominator)

        var j = path_length
        while j > cycle_start + 1:
            let index = j - 1
            let state = path[index]
            let next_state = path[index + 1] if index + 1 < path_length else path[cycle_start]
            let record = state * actions + context.policy[state]
            context.values[state] = extend_value(context.rewards[record], context.values[next_state], p, q)
            j -= 1
        j = cycle_start
        while j > 0:
            let index = j - 1
            let state = path[index]
            let next_state = path[index + 1]
            let record = state * actions + context.policy[state]
            context.values[state] = extend_value(context.rewards[record], context.values[next_state], p, q)
            j -= 1

fn improve_policy(mut context: PolicyContext, states: Int, actions: Int, p: Int64, q: Int64) -> Int:
    var changed = 0
    for state in range(states):
        var best_action = 0
        let best_record = state * actions
        let best_next = Int(context.successors[best_record])
        var best = extend_value(context.rewards[best_record], context.values[best_next], p, q)
        for action in range(1, actions):
            let record = state * actions + action
            let next_state = Int(context.successors[record])
            let candidate = extend_value(context.rewards[record], context.values[next_state], p, q)
            if candidate.numerator * best.denominator > best.numerator * candidate.denominator:
                best_action = action
                best = candidate
        if context.policy[state] != best_action:
            context.policy[state] = best_action
            changed += 1
    return changed

fn write_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("mdp_policy_iteration")
fn mdp_policy_iteration(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 28: return -1
    if input[0] < 1 or input[0] > MAX_STATES or input[1] < 1 or input[1] > MAX_ACTIONS: return -1
    if input[3] < 1 or input[3] > 4 or input[2] < 0 or input[2] >= input[3]: return -1
    let states = Int(input[0])
    let actions = Int(input[1])
    let p = input[2]
    let q = input[3]
    if Int(length) != 4 + 2 * states * actions: return -1

    var context = PolicyContext(
        rewards=InlineArray[Int64, MAX_RECORDS](fill=0),
        successors=InlineArray[Int64, MAX_RECORDS](fill=0),
        policy=InlineArray[Int, MAX_STATES](fill=0),
        values=InlineArray[Fraction, MAX_STATES](fill=Fraction(numerator=0, denominator=1)),
    )
    for i in range(states * actions):
        let reward = input[4 + 2 * i]
        let successor = input[5 + 2 * i]
        if reward < -20 or reward > 20 or successor < 0 or successor >= input[0]: return -1
        context.rewards[i] = reward
        context.successors[i] = successor
    var policy_count = 1
    for _ in range(states): policy_count *= actions
    var stable = False
    for _ in range(policy_count + 1):
        evaluate_policy(mut context, states, actions, p, q)
        if improve_policy(mut context, states, actions, p, q) == 0:
            stable = True
            break
    if not stable: return -1

    var words = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    words[0] = Int64(states)
    for state in range(states):
        words[1 + state] = Int64(context.policy[state])
        words[1 + states + 2 * state] = context.values[state].numerator
        words[2 + states + 2 * state] = context.values[state].denominator
    let output_bytes = (1 + 3 * states) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for i in range(1 + 3 * states): write_i64_le(output, i * 8, words[i])
    return Int64(output_bytes)
