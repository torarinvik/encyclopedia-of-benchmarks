module weight_conversions

const max_amount = i64(1000000)

fn append_text(mut buffer []u8, position int, text string) int {
	for index in 0 .. text.len {
		buffer[position + index] = text[index]
	}
	return position + text.len
}

fn append_i64(mut buffer []u8, position_input int, value i64) int {
	mut position := position_input
	mut digits := [24]u8{}
	mut count := 0
	mut magnitude := value
	if magnitude < 0 {
		buffer[position] = `-`
		position++
		magnitude = -magnitude
	}
	for {
		digits[count] = u8(`0` + magnitude % 10)
		count++
		magnitude /= 10
		if magnitude == 0 { break }
	}
	for count > 0 {
		count--
		buffer[position] = digits[count]
		position++
	}
	return position
}

fn append_fixed(mut buffer []u8, position_input int, value f64) int {
	mut position := position_input
	scaled := value * 100.0
	mut cents := i64(scaled + 0.5)
	if value < 0.0 { cents = -i64(-scaled + 0.5) }
	if value > 0.0 && (f64(cents) + 0.5) / 100.0 <= value { cents++ }
	else if value < 0.0 && (f64(cents) - 0.5) / 100.0 >= value { cents-- }
	if cents < 0 {
		buffer[position] = `-`
		position++
		cents = -cents
	}
	position = append_i64(mut buffer, position, cents / 100)
	fraction := cents % 100
	buffer[position] = `.`
	position++
	if fraction == 0 {
		buffer[position] = `0`
		position++
	} else if fraction % 10 == 0 {
		buffer[position] = u8(`0` + fraction / 10)
		position++
	} else {
		buffer[position] = u8(`0` + fraction / 10)
		buffer[position + 1] = u8(`0` + fraction % 10)
		position += 2
	}
	return position
}

@[export: 'weight_conversions']
pub fn weight_conversions(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length != 2 { return -1 }
	operation := unsafe { input[0] }
	amount := unsafe { input[1] }
	if operation < 0 || operation > 5 || amount < -max_amount || amount > max_amount { return -1 }
	mut buffer := [64]u8{}
	mut position := 0
	mut converted := i64(0)
	if operation == 0 {
		position = append_i64(mut buffer[..], position, amount)
		position = append_text(mut buffer[..], position, ' kg = ')
		position = append_i64(mut buffer[..], position, amount * 1000)
		position = append_text(mut buffer[..], position, ' g')
	} else if operation == 1 {
		converted = amount / 1000
		if amount < 0 { converted = -((-amount + 999) / 1000) }
		position = append_i64(mut buffer[..], position, amount)
		position = append_text(mut buffer[..], position, ' g = ')
		position = append_i64(mut buffer[..], position, converted)
		position = append_text(mut buffer[..], position, ' kg')
	} else if operation == 2 {
		position = append_i64(mut buffer[..], position, amount)
		position = append_text(mut buffer[..], position, ' lb = ')
		position = append_i64(mut buffer[..], position, amount * 16)
		position = append_text(mut buffer[..], position, ' oz')
	} else if operation == 3 {
		converted = amount / 16
		if amount < 0 { converted = -((-amount + 15) / 16) }
		position = append_i64(mut buffer[..], position, amount)
		position = append_text(mut buffer[..], position, ' oz = ')
		position = append_i64(mut buffer[..], position, converted)
		position = append_text(mut buffer[..], position, ' lb')
	} else if operation == 4 {
		position = append_i64(mut buffer[..], position, amount)
		position = append_text(mut buffer[..], position, ' kg = ')
		position = append_fixed(mut buffer[..], position, f64(amount) * 2.205)
		position = append_text(mut buffer[..], position, ' lb')
	} else {
		position = append_i64(mut buffer[..], position, amount)
		position = append_text(mut buffer[..], position, ' lb = ')
		position = append_fixed(mut buffer[..], position, f64(amount) / 2.205)
		position = append_text(mut buffer[..], position, ' kg')
	}
	buffer[position] = 0
	if output_capacity < position + 1 { return -2 }
	unsafe {
		for index in 0 .. position + 1 { output[index] = buffer[index] }
	}
	return i64(position)
}
