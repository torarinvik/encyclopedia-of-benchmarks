module print_multiplication_table

fn decimal_length(value i64) int {
	mut magnitude := value
	mut length := 1
	if magnitude < 0 { length++; magnitude = -magnitude }
	for magnitude >= 10 { magnitude /= 10; length++ }
	return length
}

fn append_decimal(mut output &u8, mut position &int, value i64) {
	mut magnitude := value
	if magnitude < 0 {
		unsafe { output[position] = u8('-') }
		position++
		magnitude = -magnitude
	}
	mut reversed := [20]u8{}
	mut count := 0
	for {
		reversed[count] = u8('0' + magnitude % 10)
		count++
		magnitude /= 10
		if magnitude == 0 { break }
	}
	for count > 0 {
		count--
		unsafe { output[position] = reversed[count] }
		position++
	}
}

@[export: 'print_multiplication_table']
pub fn print_multiplication_table(input &i64, length usize, mut output &u8,
		output_capacity usize) i64 {
	if input == nil || length != 2 { return -1 }
	number := unsafe { input[0] }
	terms := unsafe { input[1] }
	if number < -1_000_000 || number > 1_000_000 || terms < -20 || terms > 20 { return -1 }
	mut required := 0
	if terms > 0 { required = int(terms - 1) }
	mut multiplier := i64(1)
	for multiplier <= terms {
		product := number * multiplier
		required += decimal_length(number) + 3 + decimal_length(multiplier) + 3 + decimal_length(product)
		multiplier++
	}
	if output_capacity < usize(required) || (required > 0 && output == nil) { return -2 }
	mut position := 0
	multiplier = 1
	for multiplier <= terms {
		if multiplier > 1 {
			unsafe { output[position] = u8('\n') }
			position++
		}
		append_decimal(mut output, mut position, number)
		unsafe {
			output[position] = u8(' ')
			output[position + 1] = u8('*')
			output[position + 2] = u8(' ')
		}
		position += 3
		append_decimal(mut output, mut position, multiplier)
		unsafe {
			output[position] = u8(' ')
			output[position + 1] = u8('=')
			output[position + 2] = u8(' ')
		}
		position += 3
		append_decimal(mut output, mut position, number * multiplier)
		multiplier++
	}
	return i64(position)
}
