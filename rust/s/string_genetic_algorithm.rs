const POPULATION_SIZE: usize = 200;
const SELECTED_SIZE: usize = 50;
const ELITE_SIZE: usize = 66;

fn next_random(state: &mut u32) -> u32 {
    *state = ((*state as u64 * 48_271) % 2_147_483_647) as u32;
    *state
}

unsafe fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

/// Seeded, bounded string-evolution benchmark.
#[no_mangle]
pub unsafe extern "C" fn string_genetic_algorithm(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 6 || length > 44 { return -2; }
    let target_length_value = *values;
    let gene_count_value = *values.add(1);
    let seed_value = *values.add(2);
    let max_generations_value = *values.add(3);
    if !(1..=8).contains(&target_length_value) || !(1..=32).contains(&gene_count_value)
        || !(1..2_147_483_647).contains(&seed_value) || !(1..=1000).contains(&max_generations_value) {
        return -2;
    }
    let target_length = target_length_value as usize;
    let gene_count = gene_count_value as usize;
    let max_generations = max_generations_value as usize;
    if length != 4 + target_length + gene_count { return -2; }
    let mut target_word = 0u64;
    let mut target_symbols = 0u128;
    let mut gene_symbols = 0u128;
    let mut genes = [0u8; 32];
    for index in 0..target_length {
        let value = *values.add(4 + index);
        if !(32..=126).contains(&value) { return -2; }
        target_word |= (value as u64) << (8 * index);
        target_symbols |= 1u128 << value;
    }
    for index in 0..gene_count {
        let value = *values.add(4 + target_length + index);
        if !(32..=126).contains(&value) { return -2; }
        genes[index] = value as u8;
        gene_symbols |= 1u128 << value;
    }
    if target_symbols & !gene_symbols != 0 || output.is_null() { return -2; }

    let mut random_state = seed_value as u32;
    let mut population = [0u64; POPULATION_SIZE];
    let mut next_population = [0u64; POPULATION_SIZE];
    let mut scores = [0u8; POPULATION_SIZE];
    let mut order = [0usize; POPULATION_SIZE];
    for candidate in &mut population {
        let mut word = 0u64;
        for position in 0..target_length {
            let gene = genes[(next_random(&mut random_state) as usize) % gene_count];
            word |= (gene as u64) << (8 * position);
        }
        if word == target_word {
            if output_capacity < 16 { return -2; }
            write_i64_le(output, 0, 1);
            write_i64_le(output, 8, POPULATION_SIZE as i64);
            return 16;
        }
        *candidate = word;
    }

    let mut total_population = 0i64;
    for generation in 1..=max_generations {
        total_population += POPULATION_SIZE as i64;
        let mut offsets = [0usize; 9];
        for individual in 0..POPULATION_SIZE {
            // ASCII XOR clears each byte's high bit, so the bias marks
            // unequal bytes without carrying into adjacent positions.
            let difference = population[individual] ^ target_word;
            let unequal = ((difference + 0x7f7f_7f7f_7f7f_7f7f) >> 7) & 0x0101_0101_0101_0101;
            let mismatches = (unequal.wrapping_mul(0x0101_0101_0101_0101) >> 56) as usize;
            let score = (target_length - mismatches) as u8;
            scores[individual] = score;
            offsets[mismatches] += 1;
            if score as usize == target_length {
                if output_capacity < 16 { return -2; }
                write_i64_le(output, 0, generation as i64);
                write_i64_le(output, 8, total_population);
                return 16;
            }
        }
        let mut start = 0;
        for offset in &mut offsets {
            let count = *offset;
            *offset = start;
            start += count;
        }
        for (individual, &score) in scores.iter().enumerate() {
            let bucket = &mut offsets[target_length - score as usize];
            order[*bucket] = individual;
            *bucket += 1;
        }
        let mut next_count = 0usize;
        while next_count < ELITE_SIZE {
            next_population[next_count] = population[order[next_count]];
            next_count += 1;
        }
        for parent_rank in 0..SELECTED_SIZE {
            if next_count >= POPULATION_SIZE { break; }
            let first = population[order[parent_rank]];
            let child_count = (scores[order[parent_rank]] as usize * 100) / target_length + 1;
            for _ in 0..child_count.min(10) {
                if next_count >= POPULATION_SIZE { break; }
                let second = population[order[next_random(&mut random_state) as usize % 51]];
                let cut = next_random(&mut random_state) as usize % target_length;
                let mut children = [0u64; 2];
                for position in 0..target_length {
                    let shift = 8 * position;
                    let first_gene = (first >> shift) & 0xff;
                    let second_gene = (second >> shift) & 0xff;
                    children[0] |= (if position < cut { first_gene } else { second_gene }) << shift;
                    children[1] |= (if position < cut { second_gene } else { first_gene }) << shift;
                }
                for child_index in 0..2 {
                    if next_random(&mut random_state) % 5 < 2 {
                        let position = next_random(&mut random_state) as usize % target_length;
                        let shift = 8 * position;
                        let replacement = genes[next_random(&mut random_state) as usize % gene_count] as u64;
                        children[child_index] = (children[child_index] & !(0xffu64 << shift)) | (replacement << shift);
                    }
                    if next_count < POPULATION_SIZE {
                        next_population[next_count] = children[child_index];
                        next_count += 1;
                    }
                }
                if next_count == POPULATION_SIZE { break; }
            }
            if next_count == POPULATION_SIZE { break; }
        }
        population = next_population;
    }
    -1
}
