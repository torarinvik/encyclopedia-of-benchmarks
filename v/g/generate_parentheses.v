module generate_parentheses

const RequiredBytes = [0, 2, 8, 30, 112, 420, 1584]

fn walk(pairs int, opened int, closed int, mut buffer []u8, mut output []u8, cursor int) int {
	position := opened + closed
	if position == 2 * pairs {
		mut next := cursor
		for index in 0 .. position {
			output[next] = buffer[index]
			next++
		}
		return next
	}
	mut next := cursor
	if opened < pairs {
		buffer[position] = u8('(')
		next = walk(pairs, opened + 1, closed, mut buffer, mut output, next)
	}
	if closed < opened {
		buffer[position] = u8(')')
		next = walk(pairs, opened, closed + 1, mut buffer, mut output, next)
	}
	return next
}

@[export: 'generate_parentheses']
pub fn generate_parentheses(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	pair_value := input[0]
	if pair_value < 1 || pair_value > 6 { return -1 }
	pairs := int(pair_value)
	required := RequiredBytes[pairs]
	if capacity < usize(required) || unsafe { output == nil } { return -2 }
	mut buffer := []u8{len: 12}
	mut bytes := []u8{len: required}
	cursor := walk(pairs, 0, 0, mut buffer, mut bytes, 0)
	for index in 0 .. required {
		unsafe { output[index] = bytes[index] }
	}
	return i64(cursor)
}
