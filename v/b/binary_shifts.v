module binary_shifts

fn unsigned_bits(value_in u32, mut bits []u8) int {
	mut value := value_in
	mut length := 0
	for {
		bits[length] = u8(`0`) + u8(value & 1)
		length++
		value >>= 1
		if value == 0 { break }
	}
	for left := 0; left < length / 2; left++ {
		right := length - left - 1
		temporary := bits[left]
		bits[left] = bits[right]
		bits[right] = temporary
	}
	return length
}

@[export: 'binary_shifts']
pub fn binary_shifts(values &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length != 3 { return -1 }
	operation := unsafe { values[0] }
	number := unsafe { values[1] }
	shift := unsafe { values[2] }
	if operation < 0 || operation > 2 || number < -2147483647 || number > 2147483647 ||
		shift < 0 || shift > 31 || (operation < 2 && number < 0) { return -1 }

	mut bits := []u8{len: 80, init: 0}
	mut result := []u8{len: 82, init: 0}
	mut bits_length := 0
	mut result_length := 0
	if operation == 0 || operation == 1 {
		bits_length = unsigned_bits(u32(number), mut bits)
		result[0] = u8(`0`); result[1] = u8(`b`); result_length = 2
		if operation == 0 {
			for i := 0; i < bits_length; i++ { result[result_length] = bits[i]; result_length++ }
			for i := i64(0); i < shift; i++ { result[result_length] = u8(`0`); result_length++ }
		} else if int(shift) >= bits_length {
			result[result_length] = u8(`0`); result_length++
		} else {
			for i := 0; i < bits_length - int(shift); i++ { result[result_length] = bits[i]; result_length++ }
		}
	} else {
		if number >= 0 {
			bits[0] = u8(`0`)
			mut ordinary := []u8{len: 80, init: 0}
			ordinary_length := unsigned_bits(u32(number), mut ordinary)
			for i := 0; i < ordinary_length; i++ { bits[i + 1] = ordinary[i] }
			bits_length = ordinary_length + 1
		} else {
			magnitude := u32(-number)
			magnitude_length := unsigned_bits(magnitude, mut bits)
			complement := (u32(1) << u32(magnitude_length)) - magnitude
			mut complement_bits := []u8{len: 40, init: 0}
			complement_length := unsigned_bits(complement, mut complement_bits)
			bits[0] = u8(`1`)
			mut position := 1
			for i := complement_length; i < magnitude_length; i++ { bits[position] = u8(`0`); position++ }
			for i := 0; i < complement_length; i++ { bits[position] = complement_bits[i]; position++ }
			bits_length = position
		}
		result[0] = u8(`0`); result[1] = u8(`b`); result_length = 2
		sign := bits[0]
		if int(shift) >= bits_length {
			for i := 0; i < bits_length; i++ { result[result_length] = sign; result_length++ }
		} else {
			for i := i64(0); i < shift; i++ { result[result_length] = sign; result_length++ }
			for i := 0; i < bits_length - int(shift); i++ { result[result_length] = bits[i]; result_length++ }
		}
	}
	if output_capacity < result_length { return -2 }
	unsafe {
		for i := 0; i < result_length; i++ { output[i] = result[i] }
	}
	return i64(result_length)
}
