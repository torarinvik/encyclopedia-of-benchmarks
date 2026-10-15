module infix_to_postfix_conversion

const max_expression = 256
const max_output = 512

fn is_operand(ch i64) bool {
	return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122)
}
fn is_operator(ch i64) bool { return ch == 43 || ch == 45 || ch == 42 || ch == 47 || ch == 94 }
fn precedence(ch i64) i64 {
	if ch == 43 || ch == 45 { return 1 }
	if ch == 42 || ch == 47 { return 2 }
	return 3
}
fn emit_token(mut result [max_output]u8, mut count int, token u8) int {
	if count > 0 { result[count] = 32; count++ }
	result[count] = token
	return count + 1
}

@[export: 'infix_to_postfix_conversion']
pub fn infix_to_postfix_conversion(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 { return -1 }
	expression_length := unsafe { input[0] }
	if expression_length < 0 || expression_length > max_expression || length != 1 + usize(expression_length) { return -1 }
	mut stack := [max_expression]u8{}
	mut result := [max_output]u8{}
	mut top := 0
	mut count := 0
	mut expect_operand := true
	for i in 0 .. int(expression_length) {
		ch := unsafe { input[1 + i] }
		if is_operand(ch) {
			if !expect_operand { return -1 }
			count = emit_token(mut result, count, u8(ch))
			expect_operand = false
		} else if ch == 40 {
			if !expect_operand || top == max_expression { return -1 }
			stack[top] = 40; top++
		} else if ch == 41 {
			if expect_operand { return -1 }
			for top > 0 && stack[top - 1] != 40 { top--; count = emit_token(mut result, count, stack[top]) }
			if top == 0 { return -1 }
			top--
			expect_operand = false
		} else if is_operator(ch) {
			if expect_operand { return -1 }
			for top > 0 && stack[top - 1] != 40 &&
				(precedence(ch) < precedence(i64(stack[top - 1])) ||
				 (precedence(ch) == precedence(i64(stack[top - 1])) && ch != 94)) {
				top--; count = emit_token(mut result, count, stack[top])
			}
			if top == max_expression { return -1 }
			stack[top] = u8(ch); top++
			expect_operand = true
		} else { return -1 }
	}
	if expression_length != 0 && expect_operand { return -1 }
	for top > 0 {
		top--
		if stack[top] == 40 { return -1 }
		count = emit_token(mut result, count, stack[top])
	}
	result[count] = 0; count++
	if output_capacity < count { return -2 }
	for i in 0 .. count { unsafe { output[i] = result[i] } }
	return i64(count)
}
