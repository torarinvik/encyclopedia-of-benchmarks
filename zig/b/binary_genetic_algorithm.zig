/// Seeded binary genetic minimization with the pinned MATLAB operator order.
const MAX_POPULATION: usize = 16;

fn nextWord(state: *u64) u64 {
    state.* +%= 0x9E3779B97F4A7C15;
    var value = state.*;
    value = (value ^ (value >> 30)) *% 0xBF58476D1CE4E5B9;
    value = (value ^ (value >> 27)) *% 0x94D049BB133111EB;
    return value ^ (value >> 31);
}

fn bounded(state: *u64, bound: u64) u64 {
    const threshold = (0 -% bound) % bound;
    while (true) {
        const value = nextWord(state);
        if (value >= threshold) return value % bound;
    }
}

fn unitRandom(state: *u64) f64 {
    return @as(f64, @floatFromInt(nextWord(state) >> 11)) / 9007199254740992.0;
}

fn costOf(candidate: u64, n_var: usize) i64 {
    var cost: i64 = 0;
    for (0..n_var) |gene| cost += @intCast((candidate >> @intCast(gene)) & 1);
    return cost;
}

fn selectParent(probabilities: *const [MAX_POPULATION]f64, n_pop: usize,
                total: f64, state: *u64) usize {
    const target = unitRandom(state) * total;
    var cumulative: f64 = 0.0;
    for (0..n_pop) |index| {
        cumulative += probabilities[index];
        if (target <= cumulative) return index;
    }
    return n_pop - 1;
}

fn crossover(first: u64, second: u64, n_var: usize, state: *u64,
              child1: *u64, child2: *u64) void {
    const kind = bounded(state, 3);
    child1.* = 0;
    child2.* = 0;
    if (kind == 0) {
        const cut: usize = @intCast(bounded(state, @intCast(n_var - 1)) + 1);
        for (0..n_var) |gene| {
            const bit = @as(u64, 1) << @intCast(gene);
            if (gene < cut) {
                child1.* |= first & bit;
                child2.* |= second & bit;
            } else {
                child1.* |= second & bit;
                child2.* |= first & bit;
            }
        }
    } else if (kind == 1) {
        var low: usize = @intCast(bounded(state, @intCast(n_var)) + 1);
        var high: usize = @intCast(bounded(state, @intCast(n_var - 1)) + 1);
        if (high >= low) high += 1;
        if (high < low) {
            const temporary = low;
            low = high;
            high = temporary;
        }
        for (0..n_var) |gene| {
            const bit = @as(u64, 1) << @intCast(gene);
            const exchange = gene >= low and gene < high;
            child1.* |= (if (exchange) second else first) & bit;
            child2.* |= (if (exchange) first else second) & bit;
        }
    } else {
        for (0..n_var) |gene| {
            const bit = @as(u64, 1) << @intCast(gene);
            if (bounded(state, 2) == 1) {
                child1.* |= first & bit;
                child2.* |= second & bit;
            } else {
                child1.* |= second & bit;
                child2.* |= first & bit;
            }
        }
    }
}

export fn binary_genetic_algorithm(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > 5) return -1;
    const values = input.?;
    const seed_value = values[0];
    const n_var_value = values[1];
    const n_pop_value = values[2];
    const max_it_value = values[3];
    if (length != 4 or seed_value < 0 or n_var_value < 2 or n_var_value > 32 or
        n_pop_value < 2 or n_pop_value > 16 or @mod(n_pop_value, 2) != 0 or
        max_it_value < 1 or max_it_value > 32) return -1;
    const n_var: usize = @intCast(n_var_value);
    const n_pop: usize = @intCast(n_pop_value);
    const max_it: usize = @intCast(max_it_value);
    var state: u64 = @intCast(seed_value);
    var population: [MAX_POPULATION]u64 = @splat(0);
    var best_cost: i64 = @intCast(n_var + 1);

    for (0..n_pop) |member| {
        var candidate: u64 = 0;
        for (0..n_var) |gene| candidate |= bounded(&state, 2) << @intCast(gene);
        population[member] = candidate;
        const cost = costOf(candidate, n_var);
        if (cost < best_cost) best_cost = cost;
    }

    for (0..max_it) |_| {
        var costs: [MAX_POPULATION]i64 = @splat(0);
        var total_cost: i64 = 0;
        for (0..n_pop) |member| {
            costs[member] = costOf(population[member], n_var);
            total_cost += costs[member];
        }
        const average = @as(f64, @floatFromInt(total_cost)) / @as(f64, @floatFromInt(n_pop));
        var probabilities: [MAX_POPULATION]f64 = @splat(0.0);
        var probability_total: f64 = 0.0;
        for (0..n_pop) |member| {
            const scaled = if (average != 0.0) @as(f64, @floatFromInt(costs[member])) / average
                else @as(f64, @floatFromInt(costs[member]));
            probabilities[member] = @exp(-scaled);
            probability_total += probabilities[member];
        }

        const pairs = n_pop / 2;
        var first_children: [MAX_POPULATION / 2]u64 = @splat(0);
        var second_children: [MAX_POPULATION / 2]u64 = @splat(0);
        for (0..pairs) |pair| {
            const first_index = selectParent(&probabilities, n_pop, probability_total, &state);
            const second_index = selectParent(&probabilities, n_pop, probability_total, &state);
            crossover(population[first_index], population[second_index], n_var, &state,
                &first_children[pair], &second_children[pair]);
        }

        var offspring: [MAX_POPULATION]u64 = @splat(0);
        for (0..pairs) |pair| {
            offspring[pair] = first_children[pair];
            offspring[pairs + pair] = second_children[pair];
        }
        for (0..n_pop) |member| {
            for (0..n_var) |gene| {
                if (unitRandom(&state) < 0.02) offspring[member] ^= @as(u64, 1) << @intCast(gene);
            }
            const cost = costOf(offspring[member], n_var);
            if (cost < best_cost) best_cost = cost;
        }

        var merged: [MAX_POPULATION * 2]u64 = @splat(0);
        var merged_count: usize = 0;
        for (0..n_pop) |member| {
            merged[merged_count] = population[member];
            merged_count += 1;
        }
        for (0..n_pop) |member| {
            merged[merged_count] = offspring[member];
            merged_count += 1;
        }
        for (1..merged_count) |index| {
            const selected = merged[index];
            const selected_cost = costOf(selected, n_var);
            var insertion = index;
            while (insertion > 0 and costOf(merged[insertion - 1], n_var) > selected_cost) : (insertion -= 1) {
                merged[insertion] = merged[insertion - 1];
            }
            merged[insertion] = selected;
        }
        for (0..n_pop) |member| population[member] = merged[member];
    }
    return best_cost;
}
