const POPULATION_SIZE: usize = 200;
const SELECTED_SIZE: usize = 50;
const ELITE_SIZE: usize = 66;

fn nextRandom(state: *u32) u32 {
    state.* = @intCast((@as(u64, state.*) * 48_271) % 2_147_483_647);
    return state.*;
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

/// Seeded, bounded string-evolution benchmark.
export fn string_genetic_algorithm(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 6 or length > 44) return -2;
    const target_length_value = values[0];
    const gene_count_value = values[1];
    const seed_value = values[2];
    const max_generations_value = values[3];
    if (target_length_value < 1 or target_length_value > 8 or gene_count_value < 1 or gene_count_value > 32 or
        seed_value < 1 or seed_value >= 2_147_483_647 or max_generations_value < 1 or max_generations_value > 1000) return -2;
    const target_length: usize = @intCast(target_length_value);
    const gene_count: usize = @intCast(gene_count_value);
    const max_generations: usize = @intCast(max_generations_value);
    if (length != 4 + target_length + gene_count) return -2;
    var target_word: u64 = 0;
    var target_symbols: u128 = 0;
    var gene_symbols: u128 = 0;
    var genes: [32]u8 = @splat(0);
    for (0..target_length) |index| {
        const value = values[4 + index];
        if (value < 32 or value > 126) return -2;
        target_word |= @as(u64, @intCast(value)) << @intCast(8 * index);
        target_symbols |= @as(u128, 1) << @intCast(value);
    }
    for (0..gene_count) |index| {
        const value = values[4 + target_length + index];
        if (value < 32 or value > 126) return -2;
        genes[index] = @intCast(value);
        gene_symbols |= @as(u128, 1) << @intCast(value);
    }
    if (target_symbols & ~gene_symbols != 0 or output == null) return -2;

    var random_state: u32 = @intCast(seed_value);
    var population: [POPULATION_SIZE]u64 = @splat(0);
    var next_population: [POPULATION_SIZE]u64 = @splat(0);
    var mismatches: [POPULATION_SIZE]u8 = @splat(0);
    var order: [POPULATION_SIZE]usize = @splat(0);
    for (0..POPULATION_SIZE) |individual| {
        var word: u64 = 0;
        for (0..target_length) |position| {
            const gene = genes[@as(usize, @intCast(nextRandom(&random_state))) % gene_count];
            word |= @as(u64, gene) << @intCast(8 * position);
        }
        if (word == target_word) {
            if (output_capacity < 16) return -2;
            writeI64Le(output, 0, 1);
            writeI64Le(output, 8, POPULATION_SIZE);
            return 16;
        }
        population[individual] = word;
    }

    var total_population: i64 = 0;
    for (1..max_generations + 1) |generation| {
        total_population += @intCast(POPULATION_SIZE);
        var offsets: [9]usize = @splat(0);
        for (0..POPULATION_SIZE) |individual| {
            // The bias marks unequal ASCII bytes without carrying across bytes.
            const difference = population[individual] ^ target_word;
            const unequal = ((difference + 0x7f7f7f7f7f7f7f7f) >> 7) & 0x0101010101010101;
            const count: u8 = @intCast((unequal *% 0x0101010101010101) >> 56);
            mismatches[individual] = count;
            offsets[count] += 1;
            if (count == 0) {
                if (output_capacity < 16) return -2;
                writeI64Le(output, 0, @intCast(generation));
                writeI64Le(output, 8, total_population);
                return 16;
            }
        }
        var start: usize = 0;
        for (&offsets) |*offset| {
            const count = offset.*;
            offset.* = start;
            start += count;
        }
        for (mismatches, 0..) |count, individual| {
            order[offsets[count]] = individual;
            offsets[count] += 1;
        }
        var next_count: usize = 0;
        while (next_count < ELITE_SIZE) : (next_count += 1) next_population[next_count] = population[order[next_count]];
        for (0..SELECTED_SIZE) |parent_rank| {
            if (next_count >= POPULATION_SIZE) break;
            const first = population[order[parent_rank]];
            const child_count = ((target_length - mismatches[order[parent_rank]]) * 100) / target_length + 1;
            for (0..@min(child_count, 10)) |_| {
                if (next_count >= POPULATION_SIZE) break;
                const second = population[order[@as(usize, @intCast(nextRandom(&random_state))) % 51]];
                const cut = @as(usize, @intCast(nextRandom(&random_state))) % target_length;
                const low_mask = (@as(u64, 1) << @as(u6, @intCast(8 * cut))) - 1;
                var children = [2]u64{
                    (first & low_mask) | (second & ~low_mask),
                    (second & low_mask) | (first & ~low_mask),
                };
                for (0..2) |child_index| {
                    if (nextRandom(&random_state) % 5 < 2) {
                        const position = @as(usize, @intCast(nextRandom(&random_state))) % target_length;
                        const shift: u6 = @intCast(8 * position);
                        const replacement = genes[@as(usize, @intCast(nextRandom(&random_state))) % gene_count];
                        children[child_index] = (children[child_index] & ~(@as(u64, 0xff) << shift)) |
                                                (@as(u64, replacement) << shift);
                    }
                    if (next_count < POPULATION_SIZE) {
                        next_population[next_count] = children[child_index];
                        next_count += 1;
                    }
                }
                if (next_count == POPULATION_SIZE) break;
            }
            if (next_count == POPULATION_SIZE) break;
        }
        population = next_population;
    }
    return -1;
}
