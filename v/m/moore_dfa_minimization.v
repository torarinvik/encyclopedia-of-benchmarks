module moore_dfa_minimization

const max_states = 8
const max_alphabet = 3

@[export: 'moore_dfa_minimization']
pub fn moore_dfa_minimization(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 4 || length > 29 { return -1 }
	unsafe {
		n64 := input[0]
		alphabet64 := input[1]
		start64 := input[2]
		accepting := input[3]
		if n64 < 1 || n64 > max_states || alphabet64 < 1 || alphabet64 > max_alphabet { return -1 }
		if start64 < 0 || start64 >= n64 || accepting < 0 || accepting >= (i64(1) << n64) { return -1 }
		n := int(n64)
		alphabet := int(alphabet64)
		if length != usize(4 + n * alphabet) { return -1 }
		mut transitions := [max_states][max_alphabet]int{}
		for state in 0 .. n {
			for symbol in 0 .. alphabet {
				target := input[4 + state * alphabet + symbol]
				if target < 0 || target >= n64 { return -1 }
				transitions[state][symbol] = int(target)
			}
		}
		mut labels := [max_states]int{}
		mut refined := [max_states]int{}
		mut acceptance_id := [2]int{-1, -1}
		mut classes := 0
		for state in 0 .. n {
			bit := int((accepting >> state) & 1)
			if acceptance_id[bit] < 0 { acceptance_id[bit] = classes; classes++ }
			labels[state] = acceptance_id[bit]
		}
		mut rounds := 0
		for {
			mut signatures := [max_states]int{}
			mut signature_count := 0
			for state in 0 .. n {
				mut signature := labels[state]
				for symbol in 0 .. alphabet { signature = signature * max_states + labels[transitions[state][symbol]] }
				mut id := 0
				for id < signature_count && signatures[id] != signature { id++ }
				if id == signature_count { signatures[signature_count] = signature; signature_count++ }
				refined[state] = id
			}
			mut changed := false
			for state in 0 .. n { if refined[state] != labels[state] { changed = true } }
			if !changed { classes = signature_count; break }
			for state in 0 .. n { labels[state] = refined[state] }
			classes = signature_count
			rounds++
		}
		mut packed := (i64(classes) << 28) | (i64(rounds) << 24)
		for state in 0 .. n { packed |= i64(labels[state]) << (3 * state) }
		return packed
	}
}
