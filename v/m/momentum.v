module momentum

const max_length = 64
const iterations = 100
const learning_rate = 0.01
const beta = 0.9

@[export: 'momentum']
pub fn momentum(input &f64, length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || length == 0 || length > usize(max_length) { return -1 }
		count := int(length)
		mut values := [max_length]f64{}
		mut velocity := [max_length]f64{}
		mut gradient := [max_length]f64{}
		for index in 0 .. count {
			value := input[index]
			if value != value || value < -1000000.0 || value > 1000000.0 { return -1 }
			values[index] = value
		}
		if output == nil || output_capacity < length { return -2 }

		for _ in 0 .. iterations {
			for index in 0 .. count { gradient[index] = 2.0 * values[index] }
			for index in 0 .. count {
				velocity[index] = beta * velocity[index] + gradient[index]
				values[index] -= learning_rate * velocity[index]
			}
		}
		for index in 0 .. count { output[index] = values[index] }
		return i64(count)
	}
}
