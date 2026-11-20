package slide_window_aggregation_deque

import "core:c"

MAX_OPERATIONS :: 32
MAX_INPUT_LENGTH :: 162
MODULUS :: i64(97)

Matrix :: struct { a, b, c, d: i64 }

identity :: proc "contextless" () -> Matrix {
	return Matrix{1, 0, 0, 1}
}

multiply :: proc "contextless" (x, y: Matrix) -> Matrix {
	return Matrix{
		(x.a * y.a + x.b * y.c) % MODULUS,
		(x.a * y.b + x.b * y.d) % MODULUS,
		(x.c * y.a + x.d * y.c) % MODULUS,
		(x.c * y.b + x.d * y.d) % MODULUS,
	}
}

pack :: proc "contextless" (value: Matrix) -> i64 {
	return value.a + MODULUS * value.b + MODULUS * MODULUS * value.c +
		MODULUS * MODULUS * MODULUS * value.d
}

push_front :: proc "contextless" (items, aggregates: [^]Matrix, count: ^int, value: Matrix) {
	items[count^] = value
	if count^ == 0 {
		aggregates[count^] = value
	} else {
		aggregates[count^] = multiply(value, aggregates[count^ - 1])
	}
	count^ += 1
}

push_back :: proc "contextless" (items, aggregates: [^]Matrix, count: ^int, value: Matrix) {
	items[count^] = value
	if count^ == 0 {
		aggregates[count^] = value
	} else {
		aggregates[count^] = multiply(aggregates[count^ - 1], value)
	}
	count^ += 1
}

rebalance :: proc "contextless" (front, front_aggregates: [^]Matrix, front_count: ^int,
								 back, back_aggregates: [^]Matrix, back_count: ^int,
								 temporary: [^]Matrix) {
	front_was_empty := front_count^ == 0
	total := front_count^ + back_count^
	for i := 0; i < front_count^; i += 1 {
		temporary[i] = front[front_count^ - 1 - i]
	}
	for i := 0; i < back_count^; i += 1 {
		temporary[front_count^ + i] = back[i]
	}
	front_size := total / 2
	if front_was_empty { front_size += total % 2 }
	front_count^ = 0
	back_count^ = 0
	for i := front_size; i > 0; i -= 1 {
		push_front(front, front_aggregates, front_count, temporary[i - 1])
	}
	for i := front_size; i < total; i += 1 {
		push_back(back, back_aggregates, back_count, temporary[i])
	}
}

@(export)
slide_window_aggregation_deque :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	operation_value := input[0]
	if operation_value < 0 || operation_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_value)
	var front: [MAX_OPERATIONS]Matrix
	var front_aggregates: [MAX_OPERATIONS]Matrix
	var back: [MAX_OPERATIONS]Matrix
	var back_aggregates: [MAX_OPERATIONS]Matrix
	var temporary: [MAX_OPERATIONS]Matrix
	front_count, back_count := 0, 0
	position := 1
	query_ordinal, checksum := i64(0), i64(0)

	for _ := 0; _ < operation_count; _ += 1 {
		if position >= int(length) do return -1
		opcode := input[position]
		position += 1
		if opcode == 0 || opcode == 1 {
			if int(length) - position < 4 do return -1
			value := Matrix{input[position], input[position + 1], input[position + 2], input[position + 3]}
			if value.a < 0 || value.a >= MODULUS || value.b < 0 || value.b >= MODULUS ||
			   value.c < 0 || value.c >= MODULUS || value.d < 0 || value.d >= MODULUS do return -1
			position += 4
			if opcode == 0 { push_front(&front[0], &front_aggregates[0], &front_count, value) }
			else { push_back(&back[0], &back_aggregates[0], &back_count, value) }
		} else if opcode == 2 || opcode == 3 {
			if front_count + back_count == 0 do return -1
			if opcode == 2 {
				if front_count == 0 {
					rebalance(&front[0], &front_aggregates[0], &front_count,
							 &back[0], &back_aggregates[0], &back_count, &temporary[0])
				}
				front_count -= 1
			} else {
				if back_count == 0 {
					rebalance(&front[0], &front_aggregates[0], &front_count,
							 &back[0], &back_aggregates[0], &back_count, &temporary[0])
				}
				back_count -= 1
			}
		} else if opcode == 4 {
			left := identity()
			right := identity()
			if front_count > 0 { left = front_aggregates[front_count - 1] }
			if back_count > 0 { right = back_aggregates[back_count - 1] }
			query_ordinal += 1
			checksum += query_ordinal * (pack(multiply(left, right)) + 1)
		} else {
			return -1
		}
	}
	if position != int(length) do return -1
	return checksum
}
