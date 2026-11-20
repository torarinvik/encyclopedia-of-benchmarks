module sierpinski_curve_trace

const max_order = 2
const max_parseable_input = 2
const max_stack = 64

struct Frame {
	symbol u8
	level u8
}

fn push(mut stack [max_stack]Frame, mut top int, symbol u8, level u8) {
	stack[top] = Frame{symbol: symbol, level: level}
	top++
}

fn emit_curve(order u8, mut output &u8) int {
	mut stack := [max_stack]Frame{}
	mut top := 0
	mut written := 0
	push(mut stack, mut top, 5, 0)
	push(mut stack, mut top, 3, order)
	push(mut stack, mut top, 7, 0)
	push(mut stack, mut top, 2, order)
	push(mut stack, mut top, 9, 0)
	push(mut stack, mut top, 1, order)
	push(mut stack, mut top, 11, 0)
	push(mut stack, mut top, 0, order)
	for top > 0 {
		top--
		frame := stack[top]
		if frame.symbol >= 4 {
			unsafe { output[written] = frame.symbol - 4 }
			written++
			continue
		}
		if frame.level == 0 { continue }
		child := frame.level - 1
		match frame.symbol {
			0 {
				push(mut stack, mut top, 0, child); push(mut stack, mut top, 5, 0)
				push(mut stack, mut top, 3, child); push(mut stack, mut top, 12, 0)
				push(mut stack, mut top, 1, child); push(mut stack, mut top, 11, 0); push(mut stack, mut top, 0, child)
			}
			1 {
				push(mut stack, mut top, 1, child); push(mut stack, mut top, 11, 0)
				push(mut stack, mut top, 0, child); push(mut stack, mut top, 18, 0)
				push(mut stack, mut top, 2, child); push(mut stack, mut top, 9, 0); push(mut stack, mut top, 1, child)
			}
			2 {
				push(mut stack, mut top, 2, child); push(mut stack, mut top, 9, 0)
				push(mut stack, mut top, 1, child); push(mut stack, mut top, 16, 0)
				push(mut stack, mut top, 3, child); push(mut stack, mut top, 7, 0); push(mut stack, mut top, 2, child)
			}
			else {
				push(mut stack, mut top, 3, child); push(mut stack, mut top, 7, 0)
				push(mut stack, mut top, 2, child); push(mut stack, mut top, 14, 0)
				push(mut stack, mut top, 0, child); push(mut stack, mut top, 5, 0); push(mut stack, mut top, 3, child)
			}
		}
	}
	return written
}

@[export: 'sierpinski_curve_trace']
pub fn sierpinski_curve_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 1 || length > max_parseable_input { return -1 }
	if length != 1 { return -1 }
	order_word := input[0]
	if order_word < 0 || order_word > max_order { return -1 }
	order := int(order_word)
	mut required := 4
	for _ in 0 .. order { required *= 4 }
	if output == nil || capacity < usize(required) { return -2 }
	return i64(emit_curve(u8(order), mut output))
}
