package shunting_yard

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)
MAX_INPUT_VALUES :: 257
MAX_EXPRESSION_BYTES :: 255
MAX_OPERANDS :: 16
MAX_OPERATORS :: 15
MAX_LITERAL_BYTES :: 16
MAX_LITERAL_VALUE :: f64(1_000_000.0)
MAX_INTERMEDIATE :: f64(1_000_000_000_000.0)

rounded_multiply :: #force_no_inline proc "contextless" (left, right: f64) -> f64 {
	return left * right
}

rounded_add :: #force_no_inline proc "contextless" (left, right: f64) -> f64 {
	return left + right
}

rounded_divide :: #force_no_inline proc "contextless" (left, right: f64) -> f64 {
	return left / right
}

precedence :: proc(operator: u8) -> int {
	if operator == '^' do return 3
	if operator == '*' || operator == '/' do return 2
	return 1
}

apply_operator :: proc(numbers: ^[MAX_OPERANDS]f64, number_count: ^int, operator: u8) -> bool {
	if number_count^ < 2 do return false
	number_count^ -= 1
	right := numbers^[number_count^]
	number_count^ -= 1
	left := numbers^[number_count^]
	result := f64(0)
	if operator == '+' { result = left + right
	} else if operator == '-' { result = left - right
	} else if operator == '*' { result = left * right
	} else if operator == '/' {
		if right == 0 do return false
		result = left / right
	} else { result = math.pow_f64(left, right) }
	if result != result || result < -MAX_INTERMEDIATE || result > MAX_INTERMEDIATE do return false
	numbers^[number_count^] = result
	number_count^ += 1
	return true
}

@(export)
shunting_yard :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return INVALID_RESULT
	byte_count_value := input[0]
	if byte_count_value < 1 || byte_count_value > MAX_EXPRESSION_BYTES do return INVALID_RESULT
	byte_count := int(byte_count_value)
	if length != c.size_t(byte_count + 1) do return INVALID_RESULT

	numbers: [MAX_OPERANDS]f64
	operators: [MAX_OPERATORS]u8
	number_count, operator_count, operand_count, seen_operator_count := 0, 0, 0, 0
	position := 0
	expect_number := true
	for position < byte_count {
		raw := input[position + 1]
		if raw < 0 || raw > 127 do return INVALID_RESULT
		character := u8(raw)
		if character == ' ' || (character >= 9 && character <= 13) {
			position += 1
			continue
		}
		if expect_number {
			start := position
			integer_digits := 0
			number := f64(0)
			for position < byte_count {
				digit := input[position + 1]
				if digit < 48 || digit > 57 do break
				number = rounded_add(rounded_multiply(number, 10.0), f64(digit - 48))
				integer_digits += 1
				position += 1
			}
			if integer_digits == 0 do return INVALID_RESULT
			if position < byte_count && input[position + 1] == 46 {
				position += 1
				fraction_digits := 0
				scale := f64(0.1)
				for position < byte_count {
					digit := input[position + 1]
					if digit < 48 || digit > 57 do break
					product := rounded_multiply(f64(digit - 48), scale)
					number = rounded_add(number, product)
					scale = rounded_divide(scale, 10.0)
					fraction_digits += 1
					position += 1
				}
				if fraction_digits == 0 do return INVALID_RESULT
			}
			if position - start > MAX_LITERAL_BYTES || number > MAX_LITERAL_VALUE || operand_count >= MAX_OPERANDS do return INVALID_RESULT
			numbers[number_count] = number
			number_count += 1
			operand_count += 1
			expect_number = false
		} else {
			if character != '+' && character != '-' && character != '*' && character != '/' && character != '^' do return INVALID_RESULT
			for operator_count > 0 {
				top := operators[operator_count - 1]
				top_precedence := precedence(top)
				current_precedence := precedence(character)
				if top_precedence < current_precedence || (top_precedence == current_precedence && character == '^') do break
				operator_count -= 1
				if !apply_operator(&numbers, &number_count, top) do return INVALID_RESULT
			}
			if operator_count >= MAX_OPERATORS do return INVALID_RESULT
			operators[operator_count] = character
			operator_count += 1
			seen_operator_count += 1
			position += 1
			expect_number = true
		}
	}
	if expect_number || operand_count == 0 || seen_operator_count + 1 != operand_count do return INVALID_RESULT
	for operator_count > 0 {
		operator_count -= 1
		if !apply_operator(&numbers, &number_count, operators[operator_count]) do return INVALID_RESULT
	}
	if number_count != 1 do return INVALID_RESULT
	return numbers[0]
}
