module slide_window_aggregation_deque

const max_operations = 32
const max_input_length = 162
const modulus = i64(97)

struct Matrix {
	a i64
	b i64
	c i64
	d i64
}

struct AggregateDeque {
mut:
	front [max_operations]Matrix
	front_aggregates [max_operations]Matrix
	back [max_operations]Matrix
	back_aggregates [max_operations]Matrix
	temporary [max_operations]Matrix
	front_count int
	back_count int
}

fn identity() Matrix {
	return Matrix{a: 1, b: 0, c: 0, d: 1}
}

fn multiply(x Matrix, y Matrix) Matrix {
	return Matrix{
		a: (x.a * y.a + x.b * y.c) % modulus
		b: (x.a * y.b + x.b * y.d) % modulus
		c: (x.c * y.a + x.d * y.c) % modulus
		d: (x.c * y.b + x.d * y.d) % modulus
	}
}

fn pack(value Matrix) i64 {
	return value.a + modulus * value.b + modulus * modulus * value.c +
		modulus * modulus * modulus * value.d
}

fn push_front(mut deque AggregateDeque, value Matrix) {
	deque.front[deque.front_count] = value
	if deque.front_count == 0 {
		deque.front_aggregates[deque.front_count] = value
	} else {
		deque.front_aggregates[deque.front_count] = multiply(value, deque.front_aggregates[deque.front_count - 1])
	}
	deque.front_count++
}

fn push_back(mut deque AggregateDeque, value Matrix) {
	deque.back[deque.back_count] = value
	if deque.back_count == 0 {
		deque.back_aggregates[deque.back_count] = value
	} else {
		deque.back_aggregates[deque.back_count] = multiply(deque.back_aggregates[deque.back_count - 1], value)
	}
	deque.back_count++
}

fn rebalance(mut deque AggregateDeque) {
	front_was_empty := deque.front_count == 0
	total := deque.front_count + deque.back_count
	for i in 0 .. deque.front_count {
		deque.temporary[i] = deque.front[deque.front_count - 1 - i]
	}
	for i in 0 .. deque.back_count {
		deque.temporary[deque.front_count + i] = deque.back[i]
	}
	front_size := total / 2
	if front_was_empty { front_size += total % 2 }
	deque.front_count = 0
	deque.back_count = 0
	for i in 0 .. front_size {
		push_front(mut deque, deque.temporary[front_size - 1 - i])
	}
	for i in front_size .. total {
		push_back(mut deque, deque.temporary[i])
	}
}

@[export: 'slide_window_aggregation_deque']
pub fn slide_window_aggregation_deque(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > max_input_length { return -1 }
		operation_value := input[0]
		if operation_value < 0 || operation_value > max_operations { return -1 }
		operation_count := int(operation_value)
		mut deque := AggregateDeque{}
		mut position := 1
		mut query_ordinal := i64(0)
		mut checksum := i64(0)
		for _ in 0 .. operation_count {
			if position >= int(length) { return -1 }
			opcode := input[position]
			position++
			if opcode == 0 || opcode == 1 {
				if int(length) - position < 4 { return -1 }
				value := Matrix{a: input[position], b: input[position + 1], c: input[position + 2], d: input[position + 3]}
				if value.a < 0 || value.a >= modulus || value.b < 0 || value.b >= modulus ||
					value.c < 0 || value.c >= modulus || value.d < 0 || value.d >= modulus { return -1 }
				position += 4
				if opcode == 0 { push_front(mut deque, value) } else { push_back(mut deque, value) }
			} else if opcode == 2 || opcode == 3 {
				if deque.front_count + deque.back_count == 0 { return -1 }
				if opcode == 2 {
					if deque.front_count == 0 { rebalance(mut deque) }
					deque.front_count--
				} else {
					if deque.back_count == 0 { rebalance(mut deque) }
					deque.back_count--
				}
			} else if opcode == 4 {
				left := identity()
				right := identity()
				if deque.front_count > 0 { left = deque.front_aggregates[deque.front_count - 1] }
				if deque.back_count > 0 { right = deque.back_aggregates[deque.back_count - 1] }
				query_ordinal++
				checksum += query_ordinal * (pack(multiply(left, right)) + 1)
			} else { return -1 }
		}
		if position != int(length) { return -1 }
		return checksum
	}
}
