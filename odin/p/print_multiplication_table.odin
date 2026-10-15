package print_multiplication_table

import "core:c"

decimal_length :: proc "contextless" (value: i64) -> int {
	magnitude := value
	length := 1
	if magnitude < 0 { length += 1; magnitude = -magnitude }
	for magnitude >= 10 { magnitude /= 10; length += 1 }
	return length
}

append_decimal :: proc "contextless" (output: [^]u8, position: ^int, value: i64) {
	magnitude := value
	if magnitude < 0 { output[position^] = u8('-'); position^ += 1; magnitude = -magnitude }
	var reversed: [20]u8
	count := 0
	for {
		reversed[count] = u8('0' + magnitude % 10)
		count += 1
		magnitude /= 10
		if magnitude == 0 do break
	}
	for count > 0 {
		count -= 1
		output[position^] = reversed[count]
		position^ += 1
	}
}

@(export)
print_multiplication_table :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	number := input[0]
	terms := input[1]
	if number < -1_000_000 || number > 1_000_000 || terms < -20 || terms > 20 do return -1
	required := 0
	if terms > 0 do required = int(terms - 1)
	for multiplier := i64(1); multiplier <= terms; multiplier += 1 {
		product := number * multiplier
		required += decimal_length(number) + 3 + decimal_length(multiplier) + 3 + decimal_length(product)
	}
	if output_capacity < c.size_t(required) || (required > 0 && output == nil) do return -2
	position := 0
	for multiplier := i64(1); multiplier <= terms; multiplier += 1 {
		if multiplier > 1 { output[position] = u8('\n'); position += 1 }
		append_decimal(output, &position, number)
		output[position] = u8(' '); output[position + 1] = u8('*'); output[position + 2] = u8(' ')
		position += 3
		append_decimal(output, &position, multiplier)
		output[position] = u8(' '); output[position + 1] = u8('='); output[position + 2] = u8(' ')
		position += 3
		append_decimal(output, &position, number * multiplier)
	}
	return i64(position)
}
