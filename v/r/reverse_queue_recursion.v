module reverse_queue_recursion

const max_queue_length = 32
const max_input_length = 34

fn reverse_queue_recursive(mut queue &u8, capacity int, mut front &int, mut size &int) {
	unsafe {
		if size == 0 { return }
		value := queue[front]
		front = (front + 1) % capacity
		size--
		reverse_queue_recursive(mut queue, capacity, mut front, mut size)
		rear := (front + size) % capacity
		queue[rear] = value
		size++
	}
}

@[export: 'reverse_queue_recursion']
pub fn reverse_queue_recursion(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil {
			if input_length != 1 { return -1 }
			if output == nil { return -2 }
			return 0
		}
		if input_length < 1 || input_length > max_input_length { return -1 }
		if input[0] < 0 || input[0] > max_queue_length { return -1 }
		queue_length := int(input[0])
		if input_length != usize(queue_length + 1) { return -1 }
		for index in 0 .. queue_length {
			if input[index + 1] < 0 || input[index + 1] > 255 { return -1 }
		}
		if output == nil || output_capacity < usize(queue_length) { return -2 }

		mut queue := [max_queue_length]u8{}
		for index in 0 .. queue_length { queue[index] = u8(input[index + 1]) }
		mut front := 0
		mut size := queue_length
		reverse_queue_recursive(mut &queue[0], queue_length, mut front, mut size)
		for index in 0 .. queue_length {
			output[index] = queue[(front + index) % queue_length]
		}
		return i64(queue_length)
	}
}
