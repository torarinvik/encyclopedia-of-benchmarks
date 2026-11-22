module string_genetic_algorithm

const population_size = 200
const selected_size = 50
const elite_size = 66
const rng_modulus = u64(2147483647)

fn next_random(mut state &u64) u64 {
	unsafe {
		state[0] = (state[0] * u64(48271)) % rng_modulus
		return state[0]
	}
}

fn write_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 0xff) }
	}
}

@[export: 'string_genetic_algorithm']
pub fn string_genetic_algorithm(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 6 || length > 44 { return -2 }
	target_length_value := unsafe { values[0] }
	gene_count_value := unsafe { values[1] }
	seed_value := unsafe { values[2] }
	max_generations_value := unsafe { values[3] }
	if target_length_value < 1 || target_length_value > 8 || gene_count_value < 1 || gene_count_value > 32 ||
		seed_value < 1 || seed_value >= i64(rng_modulus) || max_generations_value < 1 || max_generations_value > 1000 { return -2 }
	target_length := int(target_length_value)
	gene_count := int(gene_count_value)
	max_generations := int(max_generations_value)
	if int(length) != 4 + target_length + gene_count { return -2 }
	mut target_word := u64(0)
	mut target_symbols := [2]u64{}
	mut gene_symbols := [2]u64{}
	mut genes := [32]u8{}
	for index in 0 .. target_length {
		value := unsafe { values[4 + index] }
		if value < 32 || value > 126 { return -2 }
		target_word |= u64(value) << (8 * index)
		target_symbols[int(value >> 6)] |= u64(1) << (value & 63)
	}
	for index in 0 .. gene_count {
		value := unsafe { values[4 + target_length + index] }
		if value < 32 || value > 126 { return -2 }
		genes[index] = u8(value)
		gene_symbols[int(value >> 6)] |= u64(1) << (value & 63)
	}
	if unsafe { output == nil } || (target_symbols[0] & ~gene_symbols[0]) != 0 ||
		(target_symbols[1] & ~gene_symbols[1]) != 0 { return -2 }

	mut state := u64(seed_value)
	mut population := [population_size]u64{}
	mut next_population := [population_size]u64{}
	mut mismatches := [population_size]u8{}
	mut order := [population_size]int{}
	for individual in 0 .. population_size {
		mut word := u64(0)
		for position in 0 .. target_length {
			gene := genes[int(next_random(mut state) % u64(gene_count))]
			word |= u64(gene) << (8 * position)
		}
		if word == target_word {
			if output_capacity < 16 { return -2 }
			write_i64_le(mut output, 0, 1)
			write_i64_le(mut output, 8, population_size)
			return 16
		}
		population[individual] = word
	}
	mut total_population := i64(0)
	for generation in 1 .. max_generations + 1 {
		total_population += population_size
		mut offsets := [9]int{}
		for individual in 0 .. population_size {
			// The bias marks unequal ASCII bytes without carrying across bytes.
			difference := population[individual] ^ target_word
			unequal := ((difference + u64(0x7f7f7f7f7f7f7f7f)) >> 7) & u64(0x0101010101010101)
			count := int((unequal * u64(0x0101010101010101)) >> 56)
			mismatches[individual] = u8(count)
			offsets[count]++
			if count == 0 {
				if output_capacity < 16 { return -2 }
				write_i64_le(mut output, 0, i64(generation))
				write_i64_le(mut output, 8, total_population)
				return 16
			}
		}
		mut start := 0
		for rank in 0 .. offsets.len {
			count := offsets[rank]
			offsets[rank] = start
			start += count
		}
		for individual in 0 .. population_size {
			count := int(mismatches[individual])
			order[offsets[count]] = individual
			offsets[count]++
		}
		mut next_count := 0
		for next_count < elite_size {
			next_population[next_count] = population[order[next_count]]
			next_count++
		}
		for parent_rank in 0 .. selected_size {
			if next_count >= population_size { break }
			first := population[order[parent_rank]]
			mut child_count := (target_length - int(mismatches[order[parent_rank]])) * 100 / target_length + 1
			if child_count > 10 { child_count = 10 }
			for _ in 0 .. child_count {
				if next_count >= population_size { break }
				second := population[order[int(next_random(mut state) % u64(51))]]
				cut := int(next_random(mut state) % u64(target_length))
				low_mask := (u64(1) << (8 * cut)) - 1
				mut children := [(first & low_mask) | (second & ~low_mask),
					(second & low_mask) | (first & ~low_mask)]!
			for child in 0 .. 2 {
				if next_random(mut state) % u64(5) < u64(2) {
					position := int(next_random(mut state) % u64(target_length))
					replacement := u64(genes[int(next_random(mut state) % u64(gene_count))])
					shift := 8 * position
					children[child] = (children[child] & ~(u64(0xff) << shift)) | (replacement << shift)
				}
				if next_count < population_size {
					next_population[next_count] = children[child]
					next_count++
				}
			}
			if next_count == population_size { break }
		}
		if next_count == population_size { break }
	}
	population = next_population
	}
	return -1
}
