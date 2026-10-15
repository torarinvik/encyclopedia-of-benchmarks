package infix_to_postfix_conversion

import "core:c"

MAX_EXPRESSION :: 256
MAX_OUTPUT :: 512

is_operand :: proc(ch: i64) -> bool {
	return (ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
}
is_operator :: proc(ch: i64) -> bool { return ch == '+' || ch == '-' || ch == '*' || ch == '/' || ch == '^' }
precedence :: proc(ch: i64) -> i64 { return if ch == '+' || ch == '-' do 1 else if ch == '*' || ch == '/' do 2 else 3 }
emit_token :: proc(result: [^]u8, count: ^int, token: u8) {
	if count^ > 0 { result[count^] = ' '; count^ += 1 }
	result[count^] = token
	count^ += 1
}

@(export)
infix_to_postfix_conversion :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	expression_length := input[0]
	if expression_length < 0 || expression_length > MAX_EXPRESSION || length != 1 + c.size_t(expression_length) do return -1
	stack: [MAX_EXPRESSION]u8
	result: [MAX_OUTPUT]u8
	top := 0
	count := 0
	expect_operand := true
	for i := 0; i < int(expression_length); i += 1 {
		ch := input[1 + i]
		if is_operand(ch) {
			if !expect_operand do return -1
			emit_token(result[:], &count, u8(ch))
			expect_operand = false
		} else if ch == '(' {
			if !expect_operand || top == MAX_EXPRESSION do return -1
			stack[top] = '('; top += 1
		} else if ch == ')' {
			if expect_operand do return -1
			for top > 0 && stack[top - 1] != '(' { top -= 1; emit_token(result[:], &count, stack[top]) }
			if top == 0 do return -1
			top -= 1
			expect_operand = false
		} else if is_operator(ch) {
			if expect_operand do return -1
			for top > 0 && stack[top - 1] != '(' &&
				(precedence(ch) < precedence(i64(stack[top - 1])) ||
				 (precedence(ch) == precedence(i64(stack[top - 1])) && ch != '^')) {
				top -= 1; emit_token(result[:], &count, stack[top])
			}
			if top == MAX_EXPRESSION do return -1
			stack[top] = u8(ch); top += 1
			expect_operand = true
		} else { return -1 }
	}
	if expression_length != 0 && expect_operand do return -1
	for top > 0 {
		top -= 1
		if stack[top] == '(' do return -1
		emit_token(result[:], &count, stack[top])
	}
	result[count] = 0; count += 1
	if output == nil || output_capacity < c.size_t(count) do return -2
	for i := 0; i < count; i += 1 { output[i] = result[i] }
	return i64(count)
}
