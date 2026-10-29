module queue_operate_all_composite

const max_operations = 64
const max_input_length = 1 + 3 * 64
const modulus = i64(998_244_353)

struct Affine {
	a i64
	b i64
}

struct AggregateQueue {
	mut:
	back_functions [max_operations]Affine
	back_aggregates [max_operations]Affine
	front_aggregates [max_operations]Affine
	back_size int
	front_size int
}

fn compose(first Affine, second Affine) Affine {
	return Affine{
		a: (second.a * first.a) % modulus
		b: (second.a * first.b + second.b) % modulus
	}
}

fn push_back(mut queue AggregateQueue, a i64, b i64) {
	function := Affine{a: a, b: b}
	queue.back_functions[queue.back_size] = function
	if queue.back_size == 0 {
		queue.back_aggregates[queue.back_size] = function
	} else {
		queue.back_aggregates[queue.back_size] = compose(queue.back_aggregates[queue.back_size - 1], function)
	}
	queue.back_size++
}

fn transfer(mut queue AggregateQueue) {
	for queue.back_size > 0 {
		queue.back_size--
		function := queue.back_functions[queue.back_size]
		if queue.front_size == 0 {
			queue.front_aggregates[queue.front_size] = function
		} else {
			queue.front_aggregates[queue.front_size] = compose(function, queue.front_aggregates[queue.front_size - 1])
		}
		queue.front_size++
	}
}

fn pop_front(mut queue AggregateQueue) bool {
	if queue.front_size == 0 { transfer(mut queue) }
	if queue.front_size == 0 { return false }
	queue.front_size--
	return true
}

fn aggregate(queue &AggregateQueue) Affine {
	mut result := Affine{a: 1, b: 0}
	if queue.front_size > 0 { result = queue.front_aggregates[queue.front_size - 1] }
	if queue.back_size > 0 {
		if queue.front_size > 0 {
			result = compose(result, queue.back_aggregates[queue.back_size - 1])
		} else {
			result = queue.back_aggregates[queue.back_size - 1]
		}
	}
	return result
}

@[export: 'queue_operate_all_composite']
pub fn queue_operate_all_composite(values &i64, length usize) i64 {
	if unsafe { values == nil } || length < 1 || length > max_input_length { return -1 }
	operation_value := unsafe { values[0] }
	if operation_value < 0 || operation_value > max_operations { return -1 }
	operation_count := int(operation_value)

	mut queue := AggregateQueue{}
	mut position := 1
	mut checksum := i64(0)
	mut query_number := i64(0)
	for _ in 0 .. operation_count {
		if position >= int(length) { return -1 }
		opcode := unsafe { values[position] }
		position++
		if opcode == 0 {
			if int(length) - position < 2 { return -1 }
			a := unsafe { values[position] }
			b := unsafe { values[position + 1] }
			position += 2
			if a < 1 || a >= modulus || b < 0 || b >= modulus { return -1 }
			push_back(mut queue, a, b)
		} else if opcode == 1 {
			if !pop_front(mut queue) { return -1 }
		} else if opcode == 2 {
			if position >= int(length) { return -1 }
			x := unsafe { values[position] }
			position++
			if x < 0 || x >= modulus { return -1 }
			function := aggregate(queue)
			answer := (function.a * x + function.b) % modulus
			query_number++
			checksum += query_number * (answer + 1)
		} else {
			return -1
		}
	}
	if position != int(length) { return -1 }
	return checksum
}
