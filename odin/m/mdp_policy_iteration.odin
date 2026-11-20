package mdp_policy_iteration

import "core:c"

MAX_STATES :: 4
MAX_ACTIONS :: 3
MAX_RECORDS :: 12
MAX_OUTPUT_WORDS :: 13

Fraction :: struct { numerator, denominator: i64 }
Policy_Context :: struct {
	rewards: [MAX_RECORDS]i64,
	successors: [MAX_RECORDS]i64,
	policy: [MAX_STATES]int,
	values: [MAX_STATES]Fraction,
}

gcd_u64 :: proc(a_value, b_value: u64) -> u64 {
	a, b := a_value, b_value
	for b != 0 {
		remainder := a % b
		a, b = b, remainder
	}
	return a
}

reduce_fraction :: proc(numerator, denominator: i64) -> Fraction {
	magnitude := u64(numerator)
	if numerator < 0 { magnitude = u64(-numerator) }
	divisor := gcd_u64(magnitude, u64(denominator))
	return Fraction{numerator / i64(divisor), denominator / i64(divisor)}
}

power_i64 :: proc(base: i64, exponent_value: int) -> i64 {
	result: i64 = 1
	for i := 0; i < exponent_value; i += 1 { result *= base }
	return result
}

extend_value :: proc(reward: i64, successor: Fraction, p, q: i64) -> Fraction {
	return reduce_fraction(reward * successor.denominator * q + p * successor.numerator,
		successor.denominator * q)
}

evaluate_policy :: proc(context: ^Policy_Context, states, actions: int, p, q: i64) {
	for start := 0; start < states; start += 1 {
		first_seen: [MAX_STATES]int
		for i := 0; i < MAX_STATES; i += 1 { first_seen[i] = -1 }
		var path: [MAX_STATES]int
		path_length := 0
		current := start
		for first_seen[current] < 0 {
			first_seen[current] = path_length
			path[path_length] = current
			path_length += 1
			state := path[path_length-1]
			record := state * actions + context.policy[state]
			current = int(context.successors[record])
		}
		cycle_start := first_seen[current]
		cycle_length := path_length - cycle_start
		var cycle_numerator: i64
		for j := 0; j < cycle_length; j += 1 {
			state := path[cycle_start+j]
			record := state * actions + context.policy[state]
			cycle_numerator += context.rewards[record] * power_i64(p, j) * power_i64(q, cycle_length-j)
		}
		context.values[path[cycle_start]] = reduce_fraction(cycle_numerator,
			power_i64(q, cycle_length)-power_i64(p, cycle_length))

		for j := path_length; j > cycle_start+1; j -= 1 {
			index := j - 1
			state := path[index]
			next_state := path[cycle_start]
			if index+1 < path_length { next_state = path[index+1] }
			record := state * actions + context.policy[state]
			context.values[state] = extend_value(context.rewards[record], context.values[next_state], p, q)
		}
		for j := cycle_start; j > 0; j -= 1 {
			index := j - 1
			state := path[index]
			record := state * actions + context.policy[state]
			context.values[state] = extend_value(context.rewards[record], context.values[path[index+1]], p, q)
		}
	}
}

improve_policy :: proc(context: ^Policy_Context, states, actions: int, p, q: i64) -> int {
	changed := 0
	for state := 0; state < states; state += 1 {
		best_action := 0
		best_record := state * actions
		best_next := int(context.successors[best_record])
		best := extend_value(context.rewards[best_record], context.values[best_next], p, q)
		for action := 1; action < actions; action += 1 {
			record := state * actions + action
			next_state := int(context.successors[record])
			candidate := extend_value(context.rewards[record], context.values[next_state], p, q)
			if candidate.numerator*best.denominator > best.numerator*candidate.denominator {
				best_action = action
				best = candidate
			}
		}
		if context.policy[state] != best_action {
			context.policy[state] = best_action
			changed += 1
		}
	}
	return changed
}

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> (byte*8)) & 255) }
}

@(export)
mdp_policy_iteration :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 28 do return -1
	if input[0] < 1 || input[0] > MAX_STATES || input[1] < 1 || input[1] > MAX_ACTIONS do return -1
	if input[3] < 1 || input[3] > 4 || input[2] < 0 || input[2] >= input[3] do return -1
	states, actions := int(input[0]), int(input[1])
	p, q := input[2], input[3]
	if length != c.size_t(4+2*states*actions) do return -1

	var context: Policy_Context
	for i := 0; i < states*actions; i += 1 {
		reward, successor := input[4+2*i], input[5+2*i]
		if reward < -20 || reward > 20 || successor < 0 || successor >= i64(states) do return -1
		context.rewards[i] = reward
		context.successors[i] = successor
	}
	for state := 0; state < MAX_STATES; state += 1 { context.values[state] = Fraction{0, 1} }
	policy_count := 1
	for i := 0; i < states; i += 1 { policy_count *= actions }
	stable := false
	for iteration := 0; iteration <= policy_count; iteration += 1 {
		evaluate_policy(&context, states, actions, p, q)
		if improve_policy(&context, states, actions, p, q) == 0 { stable = true; break }
	}
	if !stable do return -1
	var words: [MAX_OUTPUT_WORDS]i64
	words[0] = i64(states)
	for state := 0; state < states; state += 1 {
		words[1+state] = i64(context.policy[state])
		words[1+states+2*state] = context.values[state].numerator
		words[2+states+2*state] = context.values[state].denominator
	}
	output_bytes := (1+3*states)*8
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for i := 0; i < 1+3*states; i += 1 { write_i64_le(output, i*8, words[i]) }
	return i64(output_bytes)
}
