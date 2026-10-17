/* Seeded binary genetic minimization with the pinned MATLAB operator order. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_VARIABLES = 32, MAX_POPULATION = 16 };

static uint64_t next_word(uint64_t *state)
{
    *state += UINT64_C(0x9E3779B97F4A7C15);
    uint64_t value = *state;
    value = (value ^ (value >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    value = (value ^ (value >> 27)) * UINT64_C(0x94D049BB133111EB);
    return value ^ (value >> 31);
}

static uint64_t bounded(uint64_t *state, uint64_t bound)
{
    const uint64_t threshold = (UINT64_C(0) - bound) % bound;
    for (;;) {
        const uint64_t value = next_word(state);
        if (value >= threshold) return value % bound;
    }
}

static double unit_random(uint64_t *state)
{
    return (double)(next_word(state) >> 11) / 9007199254740992.0;
}

static int cost_of(uint64_t candidate, size_t n_var)
{
    int cost = 0;
    for (size_t gene = 0; gene < n_var; ++gene)
        cost += (int)((candidate >> gene) & UINT64_C(1));
    return cost;
}

static size_t select_parent(const double probabilities[MAX_POPULATION], size_t n_pop,
                            double total, uint64_t *state)
{
    const double target = unit_random(state) * total;
    double cumulative = 0.0;
    for (size_t index = 0; index < n_pop; ++index) {
        cumulative += probabilities[index];
        if (target <= cumulative) return index;
    }
    return n_pop - 1;
}

static void crossover(uint64_t first, uint64_t second, size_t n_var, uint64_t *state,
                      uint64_t *child1, uint64_t *child2)
{
    const uint64_t kind = bounded(state, UINT64_C(3));
    *child1 = 0;
    *child2 = 0;
    if (kind == 0) {
        const size_t cut = (size_t)bounded(state, (uint64_t)(n_var - 1)) + 1;
        for (size_t gene = 0; gene < n_var; ++gene) {
            const uint64_t bit = UINT64_C(1) << gene;
            if (gene < cut) {
                *child1 |= first & bit;
                *child2 |= second & bit;
            } else {
                *child1 |= second & bit;
                *child2 |= first & bit;
            }
        }
    } else if (kind == 1) {
        size_t low = (size_t)bounded(state, (uint64_t)n_var) + 1;
        size_t high = (size_t)bounded(state, (uint64_t)(n_var - 1)) + 1;
        if (high >= low) ++high;
        if (high < low) {
            const size_t temporary = low;
            low = high;
            high = temporary;
        }
        for (size_t gene = 0; gene < n_var; ++gene) {
            const uint64_t bit = UINT64_C(1) << gene;
            const int exchange = gene >= low && gene < high;
            *child1 |= (exchange ? second : first) & bit;
            *child2 |= (exchange ? first : second) & bit;
        }
    } else {
        for (size_t gene = 0; gene < n_var; ++gene) {
            const uint64_t bit = UINT64_C(1) << gene;
            if (bounded(state, UINT64_C(2)) == 1) {
                *child1 |= first & bit;
                *child2 |= second & bit;
            } else {
                *child1 |= second & bit;
                *child2 |= first & bit;
            }
        }
    }
}

int64_t binary_genetic_algorithm(const int64_t *values, size_t length)
{
    if (values == NULL || length < 4 || length > 5) return -1;
    const int64_t seed_value = values[0];
    const int64_t n_var_value = values[1];
    const int64_t n_pop_value = values[2];
    const int64_t max_it_value = values[3];
    if (length != 4 || seed_value < 0 || n_var_value < 2 || n_var_value > MAX_VARIABLES ||
        n_pop_value < 2 || n_pop_value > MAX_POPULATION || n_pop_value % 2 != 0 ||
        max_it_value < 1 || max_it_value > 32) return -1;
    const size_t n_var = (size_t)n_var_value;
    const size_t n_pop = (size_t)n_pop_value;
    const size_t max_it = (size_t)max_it_value;
    uint64_t state = (uint64_t)seed_value;
    uint64_t population[MAX_POPULATION] = {0};
    int best_cost = (int)n_var + 1;

    for (size_t member = 0; member < n_pop; ++member) {
        uint64_t candidate = 0;
        for (size_t gene = 0; gene < n_var; ++gene)
            candidate |= bounded(&state, UINT64_C(2)) << gene;
        population[member] = candidate;
        const int cost = cost_of(candidate, n_var);
        if (cost < best_cost) best_cost = cost;
    }

    for (size_t iteration = 0; iteration < max_it; ++iteration) {
        int costs[MAX_POPULATION];
        int total_cost = 0;
        for (size_t member = 0; member < n_pop; ++member) {
            costs[member] = cost_of(population[member], n_var);
            total_cost += costs[member];
        }
        const double average = (double)total_cost / (double)n_pop;
        double probabilities[MAX_POPULATION];
        double probability_total = 0.0;
        for (size_t member = 0; member < n_pop; ++member) {
            const double scaled = average != 0.0 ? (double)costs[member] / average : (double)costs[member];
            probabilities[member] = exp(-scaled);
            probability_total += probabilities[member];
        }

        const size_t pairs = n_pop / 2;
        uint64_t first_children[MAX_POPULATION / 2] = {0};
        uint64_t second_children[MAX_POPULATION / 2] = {0};
        for (size_t pair = 0; pair < pairs; ++pair) {
            const size_t first_index = select_parent(probabilities, n_pop, probability_total, &state);
            const size_t second_index = select_parent(probabilities, n_pop, probability_total, &state);
            crossover(population[first_index], population[second_index], n_var, &state,
                      &first_children[pair], &second_children[pair]);
        }

        uint64_t offspring[MAX_POPULATION] = {0};
        for (size_t pair = 0; pair < pairs; ++pair) {
            offspring[pair] = first_children[pair];
            offspring[pairs + pair] = second_children[pair];
        }
        for (size_t member = 0; member < n_pop; ++member) {
            for (size_t gene = 0; gene < n_var; ++gene)
                if (unit_random(&state) < 0.02) offspring[member] ^= UINT64_C(1) << gene;
            const int cost = cost_of(offspring[member], n_var);
            if (cost < best_cost) best_cost = cost;
        }

        uint64_t merged[MAX_POPULATION * 2];
        size_t merged_count = 0;
        for (size_t member = 0; member < n_pop; ++member) merged[merged_count++] = population[member];
        for (size_t member = 0; member < n_pop; ++member) merged[merged_count++] = offspring[member];
        for (size_t index = 1; index < merged_count; ++index) {
            const uint64_t selected = merged[index];
            const int selected_cost = cost_of(selected, n_var);
            size_t insertion = index;
            while (insertion > 0 && cost_of(merged[insertion - 1], n_var) > selected_cost) {
                merged[insertion] = merged[insertion - 1];
                --insertion;
            }
            merged[insertion] = selected;
        }
        for (size_t member = 0; member < n_pop; ++member) population[member] = merged[member];
    }
    return (int64_t)best_cost;
}
