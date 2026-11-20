module mdp_policy_iteration

const max_states = 4
const max_actions = 3
const max_records = 12
const max_output_words = 13

struct Fraction {
	numerator   i64
	denominator i64
}

struct PolicyContext {
mut:
	rewards    [max_records]i64
	successors [max_records]i64
	policy     [max_states]int
	values     [max_states]Fraction
}

fn gcd_u64(a_value u64, b_value u64) u64 {
	mut a := a_value
	mut b := b_value
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

fn reduce_fraction(numerator i64, denominator i64) Fraction {
	mut magnitude := u64(numerator)
	if numerator < 0 { magnitude = u64(-numerator) }
	divisor := gcd_u64(magnitude, u64(denominator))
	return Fraction{numerator: numerator / i64(divisor), denominator: denominator / i64(divisor)}
}

fn power_i64(base i64, exponent int) i64 {
	mut result := i64(1)
	for _ in 0 .. exponent { result *= base }
	return result
}

fn extend_value(reward i64, successor Fraction, p i64, q i64) Fraction {
	return reduce_fraction(reward * successor.denominator * q + p * successor.numerator,
		successor.denominator * q)
}

fn evaluate_policy(mut context PolicyContext, states int, actions int, p i64, q i64) {
	for start in 0 .. states {
		mut first_seen := [max_states]int{}
		for i in 0 .. max_states { first_seen[i] = -1 }
		mut path := [max_states]int{}
		mut path_length := 0
		mut current := start
		for first_seen[current] < 0 {
			first_seen[current] = path_length
			path[path_length] = current
			path_length++
			state := path[path_length - 1]
			record := state * actions + context.policy[state]
			current = int(context.successors[record])
		}
		cycle_start := first_seen[current]
		cycle_length := path_length - cycle_start
		mut cycle_numerator := i64(0)
		for j in 0 .. cycle_length {
			state := path[cycle_start + j]
			record := state * actions + context.policy[state]
			cycle_numerator += context.rewards[record] * power_i64(p, j) * power_i64(q, cycle_length - j)
		}
		context.values[path[cycle_start]] = reduce_fraction(cycle_numerator,
			power_i64(q, cycle_length) - power_i64(p, cycle_length))

		mut j := path_length
		for j > cycle_start + 1 {
			index := j - 1
			state := path[index]
			next_state := path[cycle_start]
			if index + 1 < path_length { next_state = path[index + 1] }
			record := state * actions + context.policy[state]
			context.values[state] = extend_value(context.rewards[record], context.values[next_state], p, q)
			j--
		}
		j = cycle_start
		for j > 0 {
			index := j - 1
			state := path[index]
			record := state * actions + context.policy[state]
			context.values[state] = extend_value(context.rewards[record], context.values[path[index + 1]], p, q)
			j--
		}
	}
}

fn improve_policy(mut context PolicyContext, states int, actions int, p i64, q i64) int {
	mut changed := 0
	for state in 0 .. states {
		mut best_action := 0
		best_record := state * actions
		best_next := int(context.successors[best_record])
		mut best := extend_value(context.rewards[best_record], context.values[best_next], p, q)
		for action in 1 .. actions {
			record := state * actions + action
			next_state := int(context.successors[record])
			candidate := extend_value(context.rewards[record], context.values[next_state], p, q)
			if candidate.numerator * best.denominator > best.numerator * candidate.denominator {
				best_action = action
				best = candidate
			}
		}
		if context.policy[state] != best_action {
			context.policy[state] = best_action
			changed++
		}
	}
	return changed
}

fn write_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'mdp_policy_iteration']
pub fn mdp_policy_iteration(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 28 { return -1 }
		if input[0] < 1 || input[0] > max_states || input[1] < 1 || input[1] > max_actions { return -1 }
		if input[3] < 1 || input[3] > 4 || input[2] < 0 || input[2] >= input[3] { return -1 }
		states, actions := int(input[0]), int(input[1])
		p, q := input[2], input[3]
		if length != usize(4 + 2 * states * actions) { return -1 }
		mut context := PolicyContext{}
		for i in 0 .. states * actions {
			reward, successor := input[4 + 2 * i], input[5 + 2 * i]
			if reward < -20 || reward > 20 || successor < 0 || successor >= i64(states) { return -1 }
			context.rewards[i] = reward
			context.successors[i] = successor
		}
		for state in 0 .. max_states { context.values[state] = Fraction{numerator: 0, denominator: 1} }
		mut policy_count := 1
		for _ in 0 .. states { policy_count *= actions }
		mut stable := false
		for _ in 0 .. (policy_count + 1) {
			evaluate_policy(mut context, states, actions, p, q)
			if improve_policy(mut context, states, actions, p, q) == 0 { stable = true; break }
		}
		if !stable { return -1 }
		mut words := [max_output_words]i64{}
		words[0] = i64(states)
		for state in 0 .. states {
			words[1 + state] = i64(context.policy[state])
			words[1 + states + 2 * state] = context.values[state].numerator
			words[2 + states + 2 * state] = context.values[state].denominator
		}
		output_bytes := (1 + 3 * states) * 8
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for i in 0 .. 1 + 3 * states { write_i64_le(output, i * 8, words[i]) }
		return i64(output_bytes)
	}
}
