module naive_shuffler

const max_items = 256
const rng_modulus = i64(2147483647)
const rng_period = i64(2147483646)

@[export: 'naive_shuffler']
pub fn naive_shuffler(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if length < 2 || length > max_items + 2 { return -1 }
		seed := input[0]
		count_value := input[1]
		if seed < 0 || seed >= rng_period || count_value < 0 || count_value > max_items { return -1 }
		count := int(count_value)
		if int(length) != count + 2 { return -1 }

		mut items := [max_items]u8{init: 0}
		for index := 0; index < count; index++ {
			value := input[index + 2]
			if value < 0 || value > 255 { return -1 }
			items[index] = u8(value)
		}
		if int(output_capacity) < count { return -2 }

		mut state := seed + 1
		for index := 0; index < count; index++ {
			bound := i64(count)
			limit := rng_period - rng_period % bound
			mut sample := i64(0)
			for {
				state = (state * 48271) % rng_modulus
				sample = state - 1
				if sample < limit { break }
			}
			other := int(sample % bound)
			temporary := items[index]
			items[index] = items[other]
			items[other] = temporary
		}
		for index := 0; index < count; index++ { output[index] = items[index] }
		return i64(count)
	}
}
