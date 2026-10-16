package weight_conversions

import "core:c"

MAX_AMOUNT :: i64(1_000_000)

append_text :: proc(buffer: [^]u8, position: int, text: string) -> int {
	for index := 0; index < len(text); index += 1 {
		buffer[position + index] = text[index]
	}
	return position + len(text)
}

append_i64 :: proc(buffer: [^]u8, position_input: int, value: i64) -> int {
	position := position_input
	var digits: [24]u8
	count := 0
	magnitude := value
	if magnitude < 0 {
		buffer[position] = '-'
		position += 1
		magnitude = -magnitude
	}
	for {
		digits[count] = u8('0' + magnitude % 10)
		count += 1
		magnitude /= 10
		if magnitude == 0 do break
	}
	for count > 0 {
		count -= 1
		buffer[position] = digits[count]
		position += 1
	}
	return position
}

append_fixed :: proc(buffer: [^]u8, position_input: int, value: f64) -> int {
	position := position_input
	scaled := value * 100.0
	var cents := i64(scaled + 0.5)
	if value < 0.0 do cents = -i64(-scaled + 0.5)
	if value > 0.0 && (f64(cents) + 0.5)/100.0 <= value do cents += 1
	else if value < 0.0 && (f64(cents) - 0.5)/100.0 >= value do cents -= 1
	if cents < 0 {
		buffer[position] = '-'
		position += 1
		cents = -cents
	}
	position = append_i64(buffer, position, cents/100)
	fraction := cents%100
	buffer[position] = '.'
	position += 1
	if fraction == 0 {
		buffer[position] = '0'
		position += 1
	} else if fraction%10 == 0 {
		buffer[position] = u8('0' + fraction/10)
		position += 1
	} else {
		buffer[position] = u8('0' + fraction/10)
		buffer[position + 1] = u8('0' + fraction%10)
		position += 2
	}
	return position
}

@(export)
weight_conversions :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	operation, amount := input[0], input[1]
	if operation < 0 || operation > 5 || amount < -MAX_AMOUNT || amount > MAX_AMOUNT do return -1
	var buffer: [64]u8
	position := 0
	var converted: i64 = 0
	if operation == 0 {
		position = append_i64(&buffer[0], position, amount)
		position = append_text(&buffer[0], position, " kg = ")
		position = append_i64(&buffer[0], position, amount*1000)
		position = append_text(&buffer[0], position, " g")
	} else if operation == 1 {
		converted = amount/1000
		if amount < 0 do converted = -((-amount + 999)/1000)
		position = append_i64(&buffer[0], position, amount)
		position = append_text(&buffer[0], position, " g = ")
		position = append_i64(&buffer[0], position, converted)
		position = append_text(&buffer[0], position, " kg")
	} else if operation == 2 {
		position = append_i64(&buffer[0], position, amount)
		position = append_text(&buffer[0], position, " lb = ")
		position = append_i64(&buffer[0], position, amount*16)
		position = append_text(&buffer[0], position, " oz")
	} else if operation == 3 {
		converted = amount/16
		if amount < 0 do converted = -((-amount + 15)/16)
		position = append_i64(&buffer[0], position, amount)
		position = append_text(&buffer[0], position, " oz = ")
		position = append_i64(&buffer[0], position, converted)
		position = append_text(&buffer[0], position, " lb")
	} else if operation == 4 {
		position = append_i64(&buffer[0], position, amount)
		position = append_text(&buffer[0], position, " kg = ")
		position = append_fixed(&buffer[0], position, f64(amount)*2.205)
		position = append_text(&buffer[0], position, " lb")
	} else {
		position = append_i64(&buffer[0], position, amount)
		position = append_text(&buffer[0], position, " lb = ")
		position = append_fixed(&buffer[0], position, f64(amount)/2.205)
		position = append_text(&buffer[0], position, " kg")
	}
	buffer[position] = 0
	if output == nil || output_capacity < c.size_t(position + 1) do return -2
	for index := 0; index <= position; index += 1 do output[index] = buffer[index]
	return i64(position)
}
