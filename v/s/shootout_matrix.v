module shootout_matrix

const matrix_size = 10
const cell_count = matrix_size * matrix_size
const max_iterations = i64(4096)
const max_output_bytes = 23

fn append_integer(value int, mut buffer [max_output_bytes]u8, mut used int) {
	mut reversed := [10]u8{}
	mut remaining := value
	mut count := 0
	for {
		reversed[count] = u8(48 + remaining % 10)
		count++
		remaining /= 10
		if remaining == 0 {
			break
		}
	}
	for count > 0 {
		count--
		buffer[used] = reversed[count]
		used++
	}
}

@[export: 'shootout_matrix']
pub fn shootout_matrix(iteration_count i64, mut output &u8, output_capacity usize) i64 {
	if iteration_count < 0 || iteration_count > max_iterations {
		return -1
	}

	mut left := [cell_count]int{}
	mut right := [cell_count]int{}
	mut product := [cell_count]int{}
	for index in 0 .. cell_count {
		left[index] = index + 1
		right[index] = index + 1
		product[index] = index + 1
	}

	for _ in 0 .. int(iteration_count) {
		for row in 0 .. matrix_size {
			for column in 0 .. matrix_size {
				mut value := 0
				for inner in 0 .. matrix_size {
					value += left[row * matrix_size + inner] * right[inner * matrix_size + column]
				}
				product[row * matrix_size + column] = value
			}
		}
	}

	mut staged := [max_output_bytes]u8{}
	mut used := 0
	append_integer(product[0], mut staged, mut used)
	staged[used] = u8(' ')
	used++
	append_integer(product[23], mut staged, mut used)
	staged[used] = u8(' ')
	used++
	append_integer(product[32], mut staged, mut used)
	staged[used] = u8(' ')
	used++
	append_integer(product[44], mut staged, mut used)
	staged[used] = 10
	used++

	if output == nil || output_capacity < used {
		return -2
	}
	unsafe {
		for index in 0 .. used {
			output[index] = staged[index]
		}
	}
	return i64(used)
}
