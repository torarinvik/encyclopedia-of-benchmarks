package mcgill_misr

import "core:c"

MIN_EXPERIMENTS :: i64(1)
MAX_EXPERIMENTS :: i64(1_000)
MAX_OUTPUT_BYTES :: 123
MASK_48 :: u64(0xFFFFFFFFFFFF)
MASK_24 :: u64(0xFFFFFF)

next_lrand48 :: proc(state: ^u64) -> u32 {
	low := state^ & MASK_24
	high := state^ >> 24
	high_product := (high * u64(0xECE66D)) & MASK_24
	state^ = (low * u64(0x5DEECE66D) + (high_product << 24) + u64(0xB)) & MASK_48
	return u32(state^ >> 17)
}

different_experiment :: proc(random_state: ^u64, free_state: ^[10]u8) -> bool {
	var faulty_state := free_state^
	for _ in 0..<10 {
		saved_free := free_state[0]
		saved_faulty := faulty_state[0]
		random_word := next_lrand48(random_state)
		for cell in 0..<9 {
			free_state[cell] = u8((u32(free_state[cell + 1]) + random_word) & 1)
			random_probability := next_lrand48(random_state)
			if random_probability % 1000 < 250 do random_word ^= 1
			faulty_state[cell] = u8((u32(faulty_state[cell + 1]) + random_word) & 1)
			random_word >>= 1
		}
		random_word = next_lrand48(random_state)
		free_state[9] = u8((u32(saved_free) + random_word) & 1)
		random_probability := next_lrand48(random_state)
		if random_probability % 10_000 < 2_500 do random_word ^= 1
		faulty_state[9] = u8((u32(saved_faulty) + random_word) & 1)
	}
	for cell in 0..<10 { if free_state[cell] != faulty_state[cell] do return true }
	return false
}

append_text :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, text: string) {
	for byte in transmute([]u8)text {
		buffer[used^] = byte
		used^ += 1
	}
}

append_unsigned :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int, value: u64) {
	var remaining := value
	var reverse: [24]u8
	count := 0
	for {
		reverse[count] = u8(48 + remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for count > 0 {
		count -= 1
		buffer[used^] = reverse[count]
		used^ += 1
	}
}

append_probability :: proc(buffer: ^[MAX_OUTPUT_BYTES]u8, used: ^int,
		same_count, experiments: u64) {
	mantissa := u64(0)
	exponent := 0
	if same_count != 0 {
		scale := u64(1)
		for same_count * scale < experiments { scale *= 10; exponent -= 1 }
		numerator := same_count * scale * 100_000_000
		mantissa = numerator / experiments
		remainder := numerator % experiments
		if 2 * remainder > experiments || (2 * remainder == experiments && (mantissa & 1) != 0) {
			mantissa += 1
		}
		if mantissa == 1_000_000_000 { mantissa = 100_000_000; exponent += 1 }
	}
	whole := mantissa / 100_000_000
	fraction := mantissa % 100_000_000
	buffer[used^] = u8(48 + whole)
	used^ += 1
	buffer[used^] = '.'
	used^ += 1
	place := u64(10_000_000)
	for _ in 0..<8 {
		buffer[used^] = u8(48 + fraction / place)
		used^ += 1
		fraction %= place
		place /= 10
	}
	buffer[used^] = 'e'
	used^ += 1
	absolute_exponent := u32(if exponent < 0 { -exponent } else { exponent })
	buffer[used^] = if exponent < 0 { '-' } else { '+' }
	used^ += 1
	buffer[used^] = u8(48 + absolute_exponent / 10)
	used^ += 1
	buffer[used^] = u8(48 + absolute_exponent % 10)
	used^ += 1
}

@(export)
mcgill_misr :: proc "c" (experiments: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if experiments < MIN_EXPERIMENTS || experiments > MAX_EXPERIMENTS do return -1
	if output == nil do return -2
	var random_state := u64(1)
	var free_state: [10]u8
	for cell in 0..<10 { free_state[cell] = 1 }
	free_state[0] = 0
	different_count := u64(0)
	for _ in 0..<int(experiments) {
		if different_experiment(&random_state, &free_state) do different_count += 1
	}
	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	append_text(&staged, &used, "reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n ")
	append_text(&staged, &used, "10 10 2.500e-01 ")
	append_unsigned(&staged, &used, u64(experiments))
	append_text(&staged, &used, " 1000000000 1 0 0 ")
	append_probability(&staged, &used, u64(experiments) - different_count, u64(experiments))
	staged[used] = '\n'
	used += 1
	if output_capacity < c.size_t(used) do return -2
	for index in 0..<used { output[index] = staged[index] }
	return i64(used)
}
