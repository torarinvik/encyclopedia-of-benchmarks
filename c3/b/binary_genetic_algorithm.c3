module binary_genetic_algorithm;

extern fn double exp(double value);

const usz MAX_POPULATION = 16;

fn ulong next_word(ulong* state) {
    state[0] += 0x9E3779B97F4A7C15ul;
    ulong value = state[0];
    value = (value ^ (value >> 30)) * 0xBF58476D1CE4E5B9ul;
    value = (value ^ (value >> 27)) * 0x94D049BB133111EBul;
    return value ^ (value >> 31);
}

fn ulong bounded(ulong* state, ulong bound) {
    ulong threshold = (0ul - bound) % bound;
    while (true) {
        ulong value = next_word(state);
        if (value >= threshold) return value % bound;
    }
}

fn double unit_random(ulong* state) {
    return (double)(next_word(state) >> 11) / 9007199254740992.0;
}

fn long cost_of(ulong candidate, usz n_var) {
    long cost = 0;
    for (usz gene = 0; gene < n_var; gene++)
        cost += (long)((candidate >> gene) & 1ul);
    return cost;
}

fn usz select_parent(double* probabilities, usz n_pop, double total, ulong* state) {
    double target = unit_random(state) * total;
    double cumulative = 0.0;
    for (usz index = 0; index < n_pop; index++) {
        cumulative += probabilities[index];
        if (target <= cumulative) return index;
    }
    return n_pop - 1;
}

fn void crossover(ulong first, ulong second, usz n_var, ulong* state,
                  ulong* child1, ulong* child2) {
    ulong kind = bounded(state, 3ul);
    child1[0] = 0;
    child2[0] = 0;
    if (kind == 0) {
        usz cut = (usz)bounded(state, (ulong)(n_var - 1)) + 1;
        for (usz gene = 0; gene < n_var; gene++) {
            ulong bit = 1ul << gene;
            if (gene < cut) {
                child1[0] |= first & bit;
                child2[0] |= second & bit;
            } else {
                child1[0] |= second & bit;
                child2[0] |= first & bit;
            }
        }
    } else if (kind == 1) {
        usz low = (usz)bounded(state, (ulong)n_var) + 1;
        usz high = (usz)bounded(state, (ulong)(n_var - 1)) + 1;
        if (high >= low) high += 1;
        if (high < low) {
            usz temporary = low;
            low = high;
            high = temporary;
        }
        for (usz gene = 0; gene < n_var; gene++) {
            ulong bit = 1ul << gene;
            bool exchange = gene >= low && gene < high;
            if (exchange) {
                child1[0] |= second & bit;
                child2[0] |= first & bit;
            } else {
                child1[0] |= first & bit;
                child2[0] |= second & bit;
            }
        }
    } else {
        for (usz gene = 0; gene < n_var; gene++) {
            ulong bit = 1ul << gene;
            if (bounded(state, 2ul) == 1) {
                child1[0] |= first & bit;
                child2[0] |= second & bit;
            } else {
                child1[0] |= second & bit;
                child2[0] |= first & bit;
            }
        }
    }
}

fn long binary_genetic_algorithm(long* input, usz length) @export("binary_genetic_algorithm") {
    if (input == null || length < 4 || length > 5) return -1;
    long seed_value = input[0];
    long n_var_value = input[1];
    long n_pop_value = input[2];
    long max_it_value = input[3];
    if (length != 4 || seed_value < 0 || n_var_value < 2 || n_var_value > 32 ||
        n_pop_value < 2 || n_pop_value > 16 || n_pop_value % 2 != 0 ||
        max_it_value < 1 || max_it_value > 32) return -1;
    usz n_var = (usz)n_var_value;
    usz n_pop = (usz)n_pop_value;
    usz max_it = (usz)max_it_value;
    ulong state = (ulong)seed_value;
    ulong[MAX_POPULATION] population = {0};
    long best_cost = (long)n_var + 1;

    for (usz member = 0; member < n_pop; member++) {
        ulong candidate = 0;
        for (usz gene = 0; gene < n_var; gene++)
            candidate |= bounded(&state, 2ul) << gene;
        population[member] = candidate;
        long cost = cost_of(candidate, n_var);
        if (cost < best_cost) best_cost = cost;
    }

    for (usz iteration = 0; iteration < max_it; iteration++) {
        long[MAX_POPULATION] costs = {0};
        long total_cost = 0;
        for (usz member = 0; member < n_pop; member++) {
            costs[member] = cost_of(population[member], n_var);
            total_cost += costs[member];
        }
        double average = (double)total_cost / (double)n_pop;
        double[MAX_POPULATION] probabilities = {0};
        double probability_total = 0.0;
        for (usz member = 0; member < n_pop; member++) {
            double scaled = average != 0.0 ? (double)costs[member] / average : (double)costs[member];
            probabilities[member] = exp(-scaled);
            probability_total += probabilities[member];
        }

        usz pairs = n_pop / 2;
        ulong[MAX_POPULATION / 2] first_children = {0};
        ulong[MAX_POPULATION / 2] second_children = {0};
        for (usz pair = 0; pair < pairs; pair++) {
            usz first_index = select_parent(&probabilities[0], n_pop, probability_total, &state);
            usz second_index = select_parent(&probabilities[0], n_pop, probability_total, &state);
            crossover(population[first_index], population[second_index], n_var, &state,
                      &first_children[pair], &second_children[pair]);
        }

        ulong[MAX_POPULATION] offspring = {0};
        for (usz pair = 0; pair < pairs; pair++) {
            offspring[pair] = first_children[pair];
            offspring[pairs + pair] = second_children[pair];
        }
        for (usz member = 0; member < n_pop; member++) {
            for (usz gene = 0; gene < n_var; gene++)
                if (unit_random(&state) < 0.02) offspring[member] ^= 1ul << gene;
            long cost = cost_of(offspring[member], n_var);
            if (cost < best_cost) best_cost = cost;
        }

        ulong[MAX_POPULATION * 2] merged = {0};
        usz merged_count = 0;
        for (usz member = 0; member < n_pop; member++) merged[merged_count++] = population[member];
        for (usz member = 0; member < n_pop; member++) merged[merged_count++] = offspring[member];
        for (usz index = 1; index < merged_count; index++) {
            ulong selected = merged[index];
            long selected_cost = cost_of(selected, n_var);
            usz insertion = index;
            while (insertion > 0 && cost_of(merged[insertion - 1], n_var) > selected_cost) {
                merged[insertion] = merged[insertion - 1];
                insertion -= 1;
            }
            merged[insertion] = selected;
        }
        for (usz member = 0; member < n_pop; member++) population[member] = merged[member];
    }
    return best_cost;
}
