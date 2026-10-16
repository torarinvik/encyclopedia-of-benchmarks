module davis_putnam_logemann_loveland

const max_variables = 5
const max_clauses = 10
const max_clause_length = 5
const max_input_length = 2 + max_clauses * (1 + max_clause_length)

fn dpll(positive &u8, negative &u8, variable_count int, clause_count int, assigned_input u8, truth_input u8) bool {
	universe := u8((1 << variable_count) - 1)
	mut assigned := assigned_input
	mut truth := truth_input
	for {
		mut changed := false
		mut all_satisfied := true
		for clause in 0 .. clause_count {
			pos := unsafe { positive[clause] }
			neg := unsafe { negative[clause] }
			if (pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & ~truth)) != 0 { continue }
			all_satisfied = false
			open := (pos | neg) & universe & ~assigned
			if open == 0 { return false }
			if (open & (open - 1)) == 0 {
				if (pos & open) != 0 { truth |= open } else { truth &= ~open }
				assigned |= open
				changed = true
				break
			}
		}
		if all_satisfied { return true }
		if changed { continue }
		mut positive_occurrences := u8(0)
		mut negative_occurrences := u8(0)
		for clause in 0 .. clause_count {
			pos := unsafe { positive[clause] }
			neg := unsafe { negative[clause] }
			if (pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & ~truth)) != 0 { continue }
			open := (pos | neg) & universe & ~assigned
			positive_occurrences |= pos & open
			negative_occurrences |= neg & open
		}
		pure_true := positive_occurrences & ~negative_occurrences
		pure_false := negative_occurrences & ~positive_occurrences
		pure := pure_true | pure_false
		if pure != 0 {
			truth = (truth | pure_true) & ~pure_false
			assigned |= pure
			continue
		}
		break
	}
	for variable in 0 .. variable_count {
		bit := u8(1 << variable)
		if (assigned & bit) == 0 {
			return dpll(positive, negative, variable_count, clause_count, assigned | bit, truth | bit) ||
				dpll(positive, negative, variable_count, clause_count, assigned | bit, truth & ~bit)
		}
	}
	return false
}

@[export: 'davis_putnam_logemann_loveland']
pub fn davis_putnam_logemann_loveland(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 2 || length > usize(max_input_length) { return -1 }
	unsafe {
		variable_arg := values[0]
		clause_arg := values[1]
		if variable_arg < 0 || variable_arg > max_variables || clause_arg < 0 || clause_arg > max_clauses { return -1 }
		variable_count := int(variable_arg)
		clause_count := int(clause_arg)
		mut positive := [max_clauses]u8{}
		mut negative := [max_clauses]u8{}
		mut position := 2
		for clause in 0 .. clause_count {
			if position >= int(length) { return -1 }
			literal_count := values[position]
			position++
			if literal_count < 0 || literal_count > max_clause_length || literal_count > i64(int(length)-position) { return -1 }
			for _ in 0 .. int(literal_count) {
				literal := values[position]
				position++
				if literal == 0 || literal < -variable_arg || literal > variable_arg { return -1 }
				mut variable := int(literal)
				if variable < 0 { variable = -variable }
				bit := u8(1 << (variable - 1))
				if literal > 0 { positive[clause] |= bit } else { negative[clause] |= bit }
			}
		}
		if position != int(length) { return -1 }
		if dpll(&positive[0], &negative[0], variable_count, clause_count, 0, 0) { return 1 }
		return 0
	}
}
