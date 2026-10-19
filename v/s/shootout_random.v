module shootout_random

const max_call_count = i64(1_000_000)
const modulus = i64(139_968)
const fraction_scale = i64(1_000_000_000)
const max_output_bytes = 13

@[export: 'shootout_random']
pub fn shootout_random(call_count i64, mut output &u8, output_capacity usize) i64 {
	if call_count < 1 || call_count > max_call_count {
		return -1
	}

	mut state := i64(42)
	for _ in 0 .. int(call_count) {
		state = (state * 3877 + 29_573) % modulus
	}

	scaled := (100 * state * fraction_scale + modulus / 2) / modulus
	mut whole := scaled / fraction_scale
	mut fraction := scaled % fraction_scale
	mut staged := [max_output_bytes]u8{}
	mut reversed_digits := [3]u8{}
	mut digit_count := 0
	for {
		reversed_digits[digit_count] = u8(48 + whole % 10)
		digit_count++
		whole /= 10
		if whole == 0 {
			break
		}
	}

	mut used := 0
	for digit_count > 0 {
		digit_count--
		staged[used] = reversed_digits[digit_count]
		used++
	}
	staged[used] = u8('.')
	used++
	mut place := i64(100_000_000)
	for place > 0 {
		staged[used] = u8(48 + fraction / place)
		used++
		fraction %= place
		place /= 10
	}
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
