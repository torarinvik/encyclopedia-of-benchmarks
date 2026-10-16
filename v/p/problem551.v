module problem551

const max_n = i64(1000000000000000)
const state_capacity = 32768
const jump_capacity = 131072
const table_mask = state_capacity - 1

struct State {
	prefix_sum i32
	suffix i64
	head int
}
struct Jump {
	difference i64
	terms i64
	k i32
	next int
}
struct Step {
	difference i64
	terms i64
}
struct Memo {
mut:
	states []State
	jumps []Jump
	jump_count int
	failed bool
}

fn power10(exponent i64) i64 {
	mut value := i64(1)
	for _ in 0 .. int(exponent) { value *= 10 }
	return value
}
fn digit_sum(value_input i64) i64 {
	mut value := value_input
	mut total := i64(0)
	for value > 0 { total += value % 10; value /= 10 }
	return total
}
fn find_state(mut memo Memo, prefix_sum i64, suffix i64) int {
	slot := int((suffix % state_capacity + prefix_sum * 1009) % state_capacity)
	for probe in 0 .. state_capacity {
		index := (slot + probe) & table_mask
		state := memo.states[index]
		if state.head == -2 {
			memo.states[index] = State{prefix_sum: i32(prefix_sum), suffix: suffix, head: -1}
			return index
		}
		if i64(state.prefix_sum) == prefix_sum && state.suffix == suffix { return index }
	}
	memo.failed = true
	return -1
}
fn add_jump(mut memo Memo, state_index int, difference i64, terms i64, k i64) {
	if memo.jump_count >= jump_capacity { memo.failed = true; return }
	index := memo.jump_count
	memo.jump_count++
	memo.jumps[index] = Jump{difference: difference, terms: terms, k: i32(k), next: memo.states[state_index].head}
	memo.states[state_index].head = index
}
fn compute(mut value &i64, k i64, index_input i64, target i64) Step {
	mut index := index_input
	start := index
	base := power10(k)
	prefix_sum := digit_sum(value / base)
	mut suffix := value % base
	mut difference := i64(0)
	for index < target {
		index++
		addend := prefix_sum + digit_sum(suffix)
		difference += addend
		suffix += addend
		if suffix >= base { break }
	}
	value += difference
	return Step{difference: difference, terms: index - start}
}
fn next_term(mut value i64, k i64, index i64, target i64, mut memo Memo) Step {
	base := power10(k)
	prefix_sum := digit_sum(value / base)
	suffix := value % base
	max_terms := target - index
	state_index := find_state(mut memo, prefix_sum, suffix)
	if state_index < 0 { return Step{} }
	mut difference := i64(0)
	mut terms := i64(0)
	mut best := -1
	mut jump := memo.states[state_index].head
	for jump >= 0 {
		entry := memo.jumps[jump]
		if i64(entry.k) <= k && entry.terms <= max_terms && (best < 0 || entry.terms > memo.jumps[best].terms) { best = jump }
		jump = entry.next
	}
	if best >= 0 {
		entry := memo.jumps[best]
		difference = entry.difference
		terms = entry.terms
		value += difference
	}
	if terms >= max_terms || suffix + difference >= base { return Step{difference: difference, terms: terms} }
	if k > 2 {
		for !memo.failed {
			extra := next_term(mut value, k - 1, index + terms, target, mut memo)
			difference += extra.difference
			terms += extra.terms
			if terms >= max_terms || suffix + difference >= base { break }
		}
	} else {
		extra := compute(mut value, k, index + terms, target)
		difference += extra.difference
		terms += extra.terms
	}
	if !memo.failed && terms < max_terms { add_jump(mut memo, state_index, difference, terms, k) }
	return Step{difference: difference, terms: terms}
}

@[export: 'problem551']
pub fn problem551(n i64) i64 {
	if n < 1 || n > max_n { return -1 }
	mut memo := Memo{
		states: []State{len: state_capacity, init: State{head: -2}}
		jumps: []Jump{len: jump_capacity}
	}
	mut value := i64(1)
	mut jumped := i64(0)
	for jumped != n - 1 && !memo.failed {
		step := next_term(mut value, 18, 1 + jumped, n, mut memo)
		jumped += step.terms
	}
	if memo.failed { return -1 }
	return value
}
