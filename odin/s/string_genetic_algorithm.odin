package string_genetic_algorithm

import "core:c"

POPULATION_SIZE :: 200
SELECTED_SIZE :: 50
ELITE_SIZE :: 66
RNG_MODULUS :: u64(2147483647)

next_random :: proc "contextless" (state: ^u64) -> u64 {
	state^ = (state^ * 48271) % RNG_MODULUS
	return state^
}

write_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0..<8 do output[offset+byte] = u8((bits >> u32(8*byte)) & 0xff)
}

@(export)
string_genetic_algorithm :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 6 || length > 44 do return -2
	target_length_value := values[0]
	gene_count_value := values[1]
	seed_value := values[2]
	max_generations_value := values[3]
	if target_length_value < 1 || target_length_value > 8 || gene_count_value < 1 || gene_count_value > 32 ||
		seed_value < 1 || seed_value >= i64(RNG_MODULUS) || max_generations_value < 1 || max_generations_value > 1000 {
		return -2
	}
	target_length := int(target_length_value)
	gene_count := int(gene_count_value)
	max_generations := int(max_generations_value)
	if int(length) != 4+target_length+gene_count do return -2
	target: [8]u8 = {}
	genes: [32]u8 = {}
	for i in 0..<target_length {
		value := values[4+i]
		if value < 32 || value > 126 do return -2
		target[i] = u8(value)
	}
	for i in 0..<gene_count {
		value := values[4+target_length+i]
		if value < 32 || value > 126 do return -2
		genes[i] = u8(value)
	}
	for position in 0..<target_length {
		found := false
		for gene in 0..<gene_count do if genes[gene] == target[position] { found = true }
		if !found do return -2
	}
	if output == nil do return -2

	state := u64(seed_value)
	population: [POPULATION_SIZE]u64 = {}
	next_population: [POPULATION_SIZE]u64 = {}
	scores: [POPULATION_SIZE]u8 = {}
	order: [POPULATION_SIZE]int = {}
	for individual in 0..<POPULATION_SIZE {
		word: u64 = 0
		for position in 0..<target_length {
			gene := genes[int(next_random(&state)%u64(gene_count))]
			word |= u64(gene) << u32(8*position)
		}
		population[individual] = word
	}
	total_population: i64 = 0
	for generation in 1..=max_generations {
		total_population += POPULATION_SIZE
		for individual in 0..<POPULATION_SIZE {
			score: u8 = 0
			for position in 0..<target_length {
				if ((population[individual]>>u32(8*position))&0xff) == u64(target[position]) do score += 1
			}
			scores[individual] = score
			order[individual] = individual
			if int(score) == target_length {
				if output_capacity < 16 do return -2
				write_i64_le(output, 0, i64(generation))
				write_i64_le(output, 8, total_population)
				return 16
			}
		}
		for index in 1..<POPULATION_SIZE {
			selected := order[index]
			insertion := index
			for insertion > 0 && scores[order[insertion-1]] < scores[selected] {
				order[insertion] = order[insertion-1]
				insertion -= 1
			}
			order[insertion] = selected
		}
		next_count := 0
		for next_count < ELITE_SIZE {
			next_population[next_count] = population[order[next_count]]
			next_count += 1
		}
		for parent_rank in 0..<SELECTED_SIZE {
			if next_count >= POPULATION_SIZE do break
			first := population[order[parent_rank]]
			child_count := min(int(scores[order[parent_rank]])*100/target_length+1, 10)
			for _ in 0..<child_count {
				if next_count >= POPULATION_SIZE do break
				second := population[order[int(next_random(&state)%51)]]
				cut := int(next_random(&state)%u64(target_length))
				children: [2]u64 = {}
				for position in 0..<target_length {
					shift := u32(8*position)
					a := (first>>shift)&0xff
					b := (second>>shift)&0xff
					if position < cut { children[0] |= a<<shift; children[1] |= b<<shift
					} else { children[0] |= b<<shift; children[1] |= a<<shift }
				}
				for child in 0..<2 {
					if next_random(&state)%5 < 2 {
						position := int(next_random(&state)%u64(target_length))
						shift := u32(8*position)
						replacement := u64(genes[int(next_random(&state)%u64(gene_count))])
						children[child] = (children[child]&~(u64(0xff)<<shift))|(replacement<<shift)
					}
					if next_count < POPULATION_SIZE { next_population[next_count] = children[child]; next_count += 1 }
				}
				if next_count == POPULATION_SIZE do break
			}
			if next_count == POPULATION_SIZE do break
		}
		population = next_population
	}
	return -1
}
