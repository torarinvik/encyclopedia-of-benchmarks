module shunting_yard

import math

const invalid_result = f64(-1.0e300)
const max_input_values = 257
const max_expression_bytes = 255
const max_operands = 16
const max_operators = 15
const max_literal_bytes = 16
const max_literal_value = 1_000_000.0
const max_intermediate = 1_000_000_000_000.0

@[noinline]
fn rounded_multiply(left f64, right f64) f64 { return left * right }

@[noinline]
fn rounded_add(left f64, right f64) f64 { return left + right }

@[noinline]
fn rounded_divide(left f64, right f64) f64 { return left / right }

fn precedence(operator u8) int {
	if operator == `^` { return 3 }
	if operator == `*` || operator == `/` { return 2 }
	return 1
}

fn apply_operator(mut numbers [16]f64, mut number_count int, operator u8) bool {
	if number_count < 2 { return false }
	number_count--
	right := numbers[number_count]
	number_count--
	left := numbers[number_count]
	mut result := f64(0)
	if operator == `+` { result = left + right }
	else if operator == `-` { result = left - right }
	else if operator == `*` { result = left * right }
	else if operator == `/` {
		if right == 0.0 { return false }
		result = left / right
	} else { result = math.pow(left, right) }
	if result != result || result < -max_intermediate || result > max_intermediate { return false }
	numbers[number_count] = result
	number_count++
	return true
}

@[export: 'shunting_yard']
pub fn shunting_yard(input &i64, length usize) f64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_values { return invalid_result }
		byte_count_value := input[0]
		if byte_count_value < 1 || byte_count_value > max_expression_bytes { return invalid_result }
		byte_count := int(byte_count_value)
		if length != usize(byte_count + 1) { return invalid_result }

		mut numbers := [max_operands]f64{}
		mut operators := [max_operators]u8{}
		mut number_count := 0
		mut operator_count := 0
		mut operand_count := 0
		mut seen_operator_count := 0
		mut position := 0
		mut expect_number := true
		for position < byte_count {
			raw := input[position + 1]
			if raw < 0 || raw > 127 { return invalid_result }
			character := u8(raw)
			if character == ` ` || (character >= 9 && character <= 13) {
				position++
				continue
			}
			if expect_number {
				start := position
				mut integer_digits := 0
				mut number := f64(0)
				for position < byte_count {
					digit := input[position + 1]
					if digit < 48 || digit > 57 { break }
					number = rounded_add(rounded_multiply(number, 10.0), f64(digit - 48))
					integer_digits++
					position++
				}
				if integer_digits == 0 { return invalid_result }
				if position < byte_count && input[position + 1] == 46 {
					position++
					mut fraction_digits := 0
					mut scale := f64(0.1)
					for position < byte_count {
						digit := input[position + 1]
						if digit < 48 || digit > 57 { break }
						product := rounded_multiply(f64(digit - 48), scale)
						number = rounded_add(number, product)
						scale = rounded_divide(scale, 10.0)
						fraction_digits++
						position++
					}
					if fraction_digits == 0 { return invalid_result }
				}
				if position - start > max_literal_bytes || number > max_literal_value || operand_count >= max_operands {
					return invalid_result
				}
				numbers[number_count] = number
				number_count++
				operand_count++
				expect_number = false
			} else {
				if character != `+` && character != `-` && character != `*` && character != `/` && character != `^` {
					return invalid_result
				}
				for operator_count > 0 {
					top := operators[operator_count - 1]
					top_precedence := precedence(top)
					current_precedence := precedence(character)
					if top_precedence < current_precedence ||
						(top_precedence == current_precedence && character == `^`) { break }
					operator_count--
					if !apply_operator(mut numbers, mut number_count, top) { return invalid_result }
				}
				if operator_count >= max_operators { return invalid_result }
				operators[operator_count] = character
				operator_count++
				seen_operator_count++
				position++
				expect_number = true
			}
		}
		if expect_number || operand_count == 0 || seen_operator_count + 1 != operand_count { return invalid_result }
		for operator_count > 0 {
			operator_count--
			if !apply_operator(mut numbers, mut number_count, operators[operator_count]) { return invalid_result }
		}
		if number_count != 1 { return invalid_result }
		return numbers[0]
	}
}
