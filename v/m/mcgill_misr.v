module mcgill_misr

const min_experiments = i64(1)
const max_experiments = i64(1_000)
const max_output_bytes = 123
const mask_48 = u64(0xFFFFFFFFFFFF)
const mask_24 = u64(0xFFFFFF)

fn next_lrand48(mut state &u64) u32 {
	low := state & mask_24
	high := state >> 24
	high_product := (high * u64(0xECE66D)) & mask_24
	state = (low * u64(0x5DEECE66D) + (high_product << 24) + u64(0xB)) & mask_48
	return u32(state >> 17)
}

fn different_experiment(mut random_state &u64, mut free_state &u8) bool {
	mut faulty_state := [10]u8{}
	for cell in 0 .. 10 { faulty_state[cell] = free_state[cell] }
	for _ in 0 .. 10 {
		saved_free := free_state[0]
		saved_faulty := faulty_state[0]
		mut random_word := next_lrand48(mut random_state)
		for cell in 0 .. 9 {
			free_state[cell] = u8((u32(free_state[cell + 1]) + random_word) & u32(1))
			random_probability := next_lrand48(mut random_state)
			if random_probability % u32(1000) < u32(250) { random_word ^= u32(1) }
			faulty_state[cell] = u8((u32(faulty_state[cell + 1]) + random_word) & u32(1))
			random_word >>= 1
		}
		random_word = next_lrand48(mut random_state)
		free_state[9] = u8((u32(saved_free) + random_word) & u32(1))
		random_probability := next_lrand48(mut random_state)
		if random_probability % u32(10_000) < u32(2_500) { random_word ^= u32(1) }
		faulty_state[9] = u8((u32(saved_faulty) + random_word) & u32(1))
	}
	for cell in 0 .. 10 { if free_state[cell] != faulty_state[cell] { return true } }
	return false
}

fn append_text(mut buffer []u8, mut used int, text string) {
	for byte in text.bytes() { buffer[used] = byte; used++ }
}

fn append_unsigned(mut buffer []u8, mut used int, value u64) {
	mut remaining := value
	mut reverse := [24]u8{}
	mut count := 0
	for {
		reverse[count] = u8(48) + u8(remaining % u64(10))
		count++
		remaining /= u64(10)
		if remaining == 0 { break }
	}
	for count > 0 { count--; buffer[used] = reverse[count]; used++ }
}

fn append_probability(mut buffer []u8, mut used int, same_count u64, experiments u64) {
	mut mantissa := u64(0)
	mut exponent := 0
	if same_count != 0 {
		mut scale := u64(1)
		for same_count * scale < experiments { scale *= u64(10); exponent-- }
		numerator := same_count * scale * u64(100_000_000)
		mantissa = numerator / experiments
		remainder := numerator % experiments
		if u64(2) * remainder > experiments || (u64(2) * remainder == experiments && (mantissa & u64(1)) != 0) {
			mantissa++
		}
		if mantissa == u64(1_000_000_000) { mantissa = u64(100_000_000); exponent++ }
	}
	whole := mantissa / u64(100_000_000)
	mut fraction := mantissa % u64(100_000_000)
	buffer[used] = u8(48) + u8(whole)
	used++
	buffer[used] = u8('.')
	used++
	mut place := u64(10_000_000)
	for _ in 0 .. 8 {
		buffer[used] = u8(48) + u8(fraction / place)
		used++
		fraction %= place
		place /= u64(10)
	}
	buffer[used] = u8('e')
	used++
	absolute_exponent := if exponent < 0 { -exponent } else { exponent }
	buffer[used] = if exponent < 0 { u8('-') } else { u8('+') }
	used++
	buffer[used] = u8(48 + absolute_exponent / 10)
	used++
	buffer[used] = u8(48 + absolute_exponent % 10)
	used++
}

@[export: 'mcgill_misr']
pub fn mcgill_misr(experiments i64, mut output &u8, output_capacity usize) i64 {
	if experiments < min_experiments || experiments > max_experiments { return -1 }
	if unsafe { output == nil } { return -2 }
	mut random_state := u64(1)
	mut free_state := [10]u8{}
	for cell in 0 .. 10 { free_state[cell] = 1 }
	free_state[0] = 0
	mut different_count := u64(0)
	for _ in 0 .. int(experiments) {
		if different_experiment(mut random_state, mut free_state[0]) { different_count++ }
	}
	mut staged := []u8{len: max_output_bytes}
	mut used := 0
	append_text(mut staged, mut used, 'reg_len #_vect prob #_tms struct seed1 seed2 seed3 Prob same output\n ')
	append_text(mut staged, mut used, '10 10 2.500e-01 ')
	append_unsigned(mut staged, mut used, u64(experiments))
	append_text(mut staged, mut used, ' 1000000000 1 0 0 ')
	append_probability(mut staged, mut used, u64(experiments) - different_count, u64(experiments))
	staged[used] = u8(10)
	used++
	if output_capacity < usize(used) { return -2 }
	for index in 0 .. used { unsafe { output[index] = staged[index] } }
	return i64(used)
}
