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
	mut target := [8]u8{}
	mut genes := [32]u8{}
	for index in 0 .. target_length {
		value := unsafe { values[4 + index] }
		if value < 32 || value > 126 { return -2 }
		target[index] = u8(value)
	}
	for index in 0 .. gene_count {
		value := unsafe { values[4 + target_length + index] }
		if value < 32 || value > 126 { return -2 }
		genes[index] = u8(value)
	}
	for position in 0 .. target_length {
		mut found := false
		for gene in 0 .. gene_count {
			if genes[gene] == target[position] { found = true }
		}
		if !found { return -2 }
	}
	if unsafe { output == nil } { return -2 }

	mut state := u64(seed_value)
	mut population := [population_size]u64{}
	mut next_population := [population_size]u64{}
	mut scores := [population_size]u8{}
	mut order := [population_size]int{}
	for individual in 0 .. population_size {
		mut word := u64(0)
		for position in 0 .. target_length {
			gene := genes[int(next_random(mut state) % u64(gene_count))]
			word |= u64(gene) << (8 * position)
		}
		population[individual] = word
	}
	mut total_population := i64(0)
	for generation in 1 .. max_generations + 1 {
		total_population += population_size
		for individual in 0 .. population_size {
			mut score := u8(0)
			for position in 0 .. target_length {
				if u8((population[individual] >> (8 * position)) & 0xff) == target[position] { score++ }
			}
			scores[individual] = score
			order[individual] = individual
			if int(score) == target_length {
				if output_capacity < 16 { return -2 }
				write_i64_le(mut output, 0, i64(generation))
				write_i64_le(mut output, 8, total_population)
				return 16
			}
		}
		for index in 1 .. population_size {
			selected := order[index]
			mut insertion := index
			for insertion > 0 && scores[order[insertion - 1]] < scores[selected] {
				order[insertion] = order[insertion - 1]
				insertion--
			}
			order[insertion] = selected
		}
		mut next_count := 0
		for next_count < elite_size {
			next_population[next_count] = population[order[next_count]]
			next_count++
		}
		for parent_rank in 0 .. selected_size {
			if next_count >= population_size { break }
			first := population[order[parent_rank]]
			mut child_count := int(scores[order[parent_rank]]) * 100 / target_length + 1
			if child_count > 10 { child_count = 10 }
			for _ in 0 .. child_count {
				if next_count >= population_size { break }
				second := population[order[int(next_random(mut state) % u64(51))]]
				cut := int(next_random(mut state) % u64(target_length))
				mut children := [2]u64{}
				for position in 0 .. target_length {
					shift := 8 * position
					first_gene := (first >> shift) & 0xff
					second_gene := (second >> shift) & 0xff
					if position < cut {
						children[0] |= first_gene << shift
						children[1] |= second_gene << shift
					} else {
						children[0] |= second_gene << shift
						children[1] |= first_gene << shift
					}
				}
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
