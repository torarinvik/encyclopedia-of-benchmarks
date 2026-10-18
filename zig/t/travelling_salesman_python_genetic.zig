const std = @import("std");

const OUTPUT_LENGTH: usize = 5;
const MAX_POPULATION: usize = 8;

fn finite(value: f64) bool {
    return std.math.isFinite(value);
}

fn routeDistance(points: [2][2]f64, route: [3]usize) f64 {
    var total: f64 = 0;
    for (0..2) |edge| {
        const from = points[route[edge]];
        const to = points[route[edge + 1]];
        const dx = to[0] - from[0];
        const dy = to[1] - from[1];
        total += @sqrt(dx * dx + dy * dy);
    }
    return total;
}

fn computeFitness(
    points: [2][2]f64,
    chromosomes: [MAX_POPULATION][3]usize,
    population_size: usize,
    best_path: *[3]usize,
    best_distance: *f64,
    fitness: *[MAX_POPULATION]f64,
) void {
    for (0..population_size) |i| {
        const total = routeDistance(points, chromosomes[i]);
        fitness[i] = 1.0 / total;
        if (total < best_distance.*) {
            best_path.* = chromosomes[i];
            best_distance.* = total;
        }
    }
}

fn crossPair(
    chromosome_a: [3]usize,
    chromosome_b: [3]usize,
    crossover_probability: f64,
) [2][3]usize {
    var new_a = chromosome_a;
    var new_b = chromosome_b;
    if (std.crypto.random.float(f64) <= crossover_probability) {
        const first = std.crypto.random.intRangeAtMost(usize, 0, 2);
        const second = std.crypto.random.intRangeAtMost(usize, 0, 2);
        const low = @min(first, second);
        const high = @max(first, second);
        for (0..(high - low + 1)) |offset| {
            const index = low + offset;
            const temporary = new_a[index];
            new_a[index] = new_b[index];
            new_b[index] = temporary;
        }

        // The pinned duplicate repair scans interior positions after crossover.
        // With one interior city, no copied segment can introduce a new city.
        for ([2][3]usize{ new_a, new_b }) |chromosome| {
            const has_duplicate = chromosome[0] == chromosome[2];
            if (has_duplicate) {
                for (0..(high - low + 1)) |segment_offset| {
                    const segment_index = low + segment_offset;
                    var target_index: usize = 0;
                    for (1..2) |chrom_index| {
                        if (chrom_index == segment_index) continue;
                        if (chromosome[chrom_index] == chromosome[segment_index]) {
                            target_index = chrom_index;
                            break;
                        }
                    }
                    // For the valid two-city chromosome this cannot be nonzero.
                    if (target_index != 0) unreachable;
                }
            }
        }
    }
    return .{ new_a, new_b };
}

fn mutate(chromosome: [3]usize, mutation_probability: f64) [3]usize {
    var result = chromosome;
    if (std.crypto.random.float(f64) <= mutation_probability) {
        const first = std.crypto.random.intRangeAtMost(usize, 1, 1);
        const second = std.crypto.random.intRangeAtMost(usize, 1, 1);
        const temporary = result[first];
        result[first] = result[second];
        result[second] = temporary;
    }
    return result;
}

export fn travelling_salesman_python_genetic(input_opt: ?[*]const f64, input_length: usize,
    output_opt: ?[*]f64, output_capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (input_length != 8) return -1;

    for (0..input_length) |i| {
        if (!finite(input[i])) return -1;
    }
    const population = input[0];
    const iterations = input[1];
    const crossover_probability = input[2];
    const mutation_probability = input[3];
    if (@trunc(population) != population or population < 2 or population > 8 or
        @trunc(iterations) != iterations or
        iterations < 0 or iterations > 12 or
        crossover_probability < 0 or crossover_probability > 1 or
        mutation_probability < 0 or mutation_probability > 1) return -1;
    const population_int: u8 = @intFromFloat(population);
    if (population_int % 2 != 0) return -1;

    for (4..8) |i| {
        if (@trunc(input[i]) != input[i] or input[i] < -16 or input[i] > 16) return -1;
    }
    if (input[4] == input[6] and input[5] == input[7]) return -1;

    const points = [2][2]f64{
        .{ input[4], input[5] },
        .{ input[6], input[7] },
    };
    const population_size: usize = @intFromFloat(population);
    const iteration_count: usize = @intFromFloat(iterations);

    // Every source chromosome samples the sole non-origin city, then closes at 0.
    var chromosomes = [_][3]usize{.{ 0, 1, 0 }} ** MAX_POPULATION;
    for (0..population_size) |i| {
        _ = std.crypto.random.intRangeAtMost(usize, 0, 0);
        chromosomes[i] = .{ 0, 1, 0 };
    }

    var best_path: [3]usize = .{ 0, 1, 0 };
    var best_distance = std.math.inf(f64);
    var fitness: [MAX_POPULATION]f64 = undefined;
    computeFitness(points, chromosomes, population_size, &best_path, &best_distance, &fitness);

    for (0..iteration_count) |_| {
        var probability: [MAX_POPULATION]f64 = undefined;
        var total_probability: f64 = 0;
        for (0..population_size) |i| total_probability += fitness[i];
        for (0..population_size) |i| probability[i] = fitness[i] / total_probability;

        var selected = chromosomes;
        for (0..population_size) |i| {
            const random_value = std.crypto.random.float(f64);
            var cumulative: f64 = 0;
            for (0..population_size) |j| {
                cumulative += probability[j];
                if (random_value <= cumulative) {
                    selected[i] = chromosomes[j];
                    break;
                }
            }
        }
        chromosomes = selected;

        for (0..population_size / 2) |i| {
            const pair = crossPair(chromosomes[i], chromosomes[i + population_size / 2], crossover_probability);
            chromosomes[i] = pair[0];
            chromosomes[i + population_size / 2] = pair[1];
        }
        for (0..population_size) |i| chromosomes[i] = mutate(chromosomes[i], mutation_probability);
        computeFitness(points, chromosomes, population_size, &best_path, &best_distance, &fitness);
    }

    const staged = [_]f64{
        3,
        @floatFromInt(best_path[0]),
        @floatFromInt(best_path[1]),
        @floatFromInt(best_path[2]),
        best_distance,
    };

    const output = output_opt orelse return -2;
    if (output_capacity < OUTPUT_LENGTH) return -2;
    @memcpy(output[0..OUTPUT_LENGTH], staged[0..]);
    return @intCast(OUTPUT_LENGTH);
}
