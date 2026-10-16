package davis_putnam_logemann_loveland

import "core:c"

Max_Variables :: 5
Max_Clauses :: 10
Max_Clause_Length :: 5
Max_Input_Length :: 2 + Max_Clauses * (1 + Max_Clause_Length)

dpll :: proc "contextless" (positive, negative: [^]u8, variable_count, clause_count: int,
	assigned_input, truth_input: u8) -> bool {
	universe := u8((1 << uint(variable_count)) - 1)
	assigned := assigned_input
	truth := truth_input
	for {
		changed := false
		all_satisfied := true
		for clause := 0; clause < clause_count; clause += 1 {
			pos, neg := positive[clause], negative[clause]
			if (pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & ~truth)) != 0 do continue
			all_satisfied = false
			open := (pos | neg) & universe & ~assigned
			if open == 0 do return false
			if (open & (open - 1)) == 0 {
				if (pos & open) != 0 { truth |= open } else { truth &= ~open }
				assigned |= open
				changed = true
				break
			}
		}
		if all_satisfied do return true
		if changed do continue
		positive_occurrences, negative_occurrences: u8 = 0, 0
		for clause := 0; clause < clause_count; clause += 1 {
			pos, neg := positive[clause], negative[clause]
			if (pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & ~truth)) != 0 do continue
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
	for variable := 0; variable < variable_count; variable += 1 {
		bit := u8(1 << uint(variable))
		if (assigned & bit) == 0 {
			return dpll(positive, negative, variable_count, clause_count, assigned | bit, truth | bit) ||
				dpll(positive, negative, variable_count, clause_count, assigned | bit, truth & ~bit)
		}
	}
	return false
}

@(export)
davis_putnam_logemann_loveland :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(Max_Input_Length) do return -1
	variable_arg, clause_arg := values[0], values[1]
	if variable_arg < 0 || variable_arg > Max_Variables || clause_arg < 0 || clause_arg > Max_Clauses do return -1
	variable_count, clause_count := int(variable_arg), int(clause_arg)
	positive: [Max_Clauses]u8
	negative: [Max_Clauses]u8
	position := 2
	for clause := 0; clause < clause_count; clause += 1 {
		if position >= int(length) do return -1
		literal_count := values[position]
		position += 1
		if literal_count < 0 || literal_count > Max_Clause_Length || literal_count > i64(int(length)-position) do return -1
		for item := i64(0); item < literal_count; item += 1 {
			literal := values[position]
			position += 1
			if literal == 0 || literal < -variable_arg || literal > variable_arg do return -1
			variable := int(literal)
			if variable < 0 do variable = -variable
			bit := u8(1 << uint(variable - 1))
			if literal > 0 { positive[clause] |= bit } else { negative[clause] |= bit }
		}
	}
	if position != int(length) do return -1
	if dpll(&positive[0], &negative[0], variable_count, clause_count, 0, 0) do return 1
	return 0
}
