module pratt_expression_evaluation

const invalid_result = i64(-9223372036854775807 - 1)
const max_tokens = 15

struct PrattParser {
	values &i64
	count int
	mut:
		position int
		invalid bool
}

fn parse_expression(mut parser PrattParser, minimum_binding_power i64) i64 {
	if parser.position >= parser.count {
		parser.invalid = true
		return 0
	}
	offset := 1 + 2 * parser.position
	parser.position++
	kind := parser.values[offset]
	mut left := i64(0)
	if kind == 1 {
		left = parser.values[offset + 1]
	} else if kind == 3 {
		left = -parse_expression(mut parser, 25)
	} else if kind == 5 {
		left = parse_expression(mut parser, 0)
		if parser.invalid || parser.position >= parser.count || parser.values[1 + 2 * parser.position] != 6 {
			parser.invalid = true
			return 0
		}
		parser.position++
	} else {
		parser.invalid = true
		return 0
	}
	if parser.invalid { return 0 }

	for parser.position < parser.count {
		operator := parser.values[1 + 2 * parser.position]
		binding_power := if operator == 2 || operator == 3 { i64(10) } else if operator == 4 { i64(20) } else { i64(-1) }
		if binding_power < minimum_binding_power { break }
		parser.position++
		right := parse_expression(mut parser, binding_power + 1)
		if parser.invalid { return 0 }
		if operator == 2 { left += right }
		else if operator == 3 { left -= right }
		else { left *= right }
	}
	return left
}

@[export: 'pratt_expression_evaluation']
pub fn pratt_expression_evaluation(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 32 { return invalid_result }
		count_value := input[0]
		if count_value < 1 || count_value > max_tokens { return invalid_result }
		count := int(count_value)
		if length != usize(1 + 2 * count) { return invalid_result }
		for token in 0 .. count {
			kind := input[1 + 2 * token]
			payload := input[2 + 2 * token]
			if kind == 1 {
				if payload < 0 || payload > 9 { return invalid_result }
			} else if kind >= 2 && kind <= 6 {
				if payload != 0 { return invalid_result }
			} else {
				return invalid_result
			}
		}
		mut parser := PrattParser{values: input, count: count, position: 0, invalid: false}
		result := parse_expression(mut parser, 0)
		if parser.invalid || parser.position != count { return invalid_result }
		return result
	}
}
