//! Seeded binary genetic minimization with the pinned MATLAB operator order.

const MAX_POPULATION: usize = 16;

fn next_word(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut value = *state;
    value = (value ^ (value >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    value = (value ^ (value >> 27)).wrapping_mul(0x94D049BB133111EB);
    value ^ (value >> 31)
}

fn bounded(state: &mut u64, bound: u64) -> u64 {
    let threshold = 0u64.wrapping_sub(bound) % bound;
    loop {
        let value = next_word(state);
        if value >= threshold {
            return value % bound;
        }
    }
}

fn unit_random(state: &mut u64) -> f64 {
    (next_word(state) >> 11) as f64 / 9_007_199_254_740_992.0
}

fn cost_of(candidate: u64, n_var: usize) -> i64 {
    (0..n_var).map(|gene| ((candidate >> gene) & 1) as i64).sum()
}

fn select_parent(probabilities: &[f64; MAX_POPULATION], n_pop: usize,
                 total: f64, state: &mut u64) -> usize {
    let target = unit_random(state) * total;
    let mut cumulative = 0.0;
    for (index, probability) in probabilities.iter().take(n_pop).enumerate() {
        cumulative += *probability;
        if target <= cumulative {
            return index;
        }
    }
    n_pop - 1
}

fn crossover(first: u64, second: u64, n_var: usize, state: &mut u64) -> (u64, u64) {
    let kind = bounded(state, 3);
    let mut child1 = 0u64;
    let mut child2 = 0u64;
    if kind == 0 {
        let cut = bounded(state, (n_var - 1) as u64) as usize + 1;
        for gene in 0..n_var {
            let bit = 1u64 << gene;
            if gene < cut {
                child1 |= first & bit;
                child2 |= second & bit;
            } else {
                child1 |= second & bit;
                child2 |= first & bit;
            }
        }
    } else if kind == 1 {
        let mut low = bounded(state, n_var as u64) as usize + 1;
        let mut high = bounded(state, (n_var - 1) as u64) as usize + 1;
        if high >= low {
            high += 1;
        }
        if high < low {
            std::mem::swap(&mut low, &mut high);
        }
        for gene in 0..n_var {
            let bit = 1u64 << gene;
            let exchange = gene >= low && gene < high;
            child1 |= (if exchange { second } else { first }) & bit;
            child2 |= (if exchange { first } else { second }) & bit;
        }
    } else {
        for gene in 0..n_var {
            let bit = 1u64 << gene;
            if bounded(state, 2) == 1 {
                child1 |= first & bit;
                child2 |= second & bit;
            } else {
                child1 |= second & bit;
                child2 |= first & bit;
            }
        }
    }
    (child1, child2)
}

#[no_mangle]
pub unsafe extern "C" fn binary_genetic_algorithm(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(4..=5).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let seed = values[0];
    let n_var_value = values[1];
    let n_pop_value = values[2];
    let max_it_value = values[3];
    if length != 4 || seed < 0 || !(2..=32).contains(&n_var_value)
        || !(2..=16).contains(&n_pop_value) || n_pop_value % 2 != 0
        || !(1..=32).contains(&max_it_value)
    {
        return -1;
    }
    let n_var = n_var_value as usize;
    let n_pop = n_pop_value as usize;
    let max_it = max_it_value as usize;
    let mut state = seed as u64;
    let mut population = [0u64; MAX_POPULATION];
    let mut best_cost = n_var as i64 + 1;

    for member in 0..n_pop {
        let mut candidate = 0u64;
        for gene in 0..n_var {
            candidate |= bounded(&mut state, 2) << gene;
        }
        population[member] = candidate;
        let cost = cost_of(candidate, n_var);
        if cost < best_cost {
            best_cost = cost;
        }
    }

    for _ in 0..max_it {
        let mut costs = [0i64; MAX_POPULATION];
        let mut total_cost = 0i64;
        for member in 0..n_pop {
            costs[member] = cost_of(population[member], n_var);
            total_cost += costs[member];
        }
        let average = total_cost as f64 / n_pop as f64;
        let mut probabilities = [0.0f64; MAX_POPULATION];
        let mut probability_total = 0.0;
        for member in 0..n_pop {
            let scaled = if average != 0.0 { costs[member] as f64 / average }
                         else { costs[member] as f64 };
            probabilities[member] = (-scaled).exp();
            probability_total += probabilities[member];
        }

        let pairs = n_pop / 2;
        let mut first_children = [0u64; MAX_POPULATION / 2];
        let mut second_children = [0u64; MAX_POPULATION / 2];
        for pair in 0..pairs {
            let first_index = select_parent(&probabilities, n_pop, probability_total, &mut state);
            let second_index = select_parent(&probabilities, n_pop, probability_total, &mut state);
            (first_children[pair], second_children[pair]) =
                crossover(population[first_index], population[second_index], n_var, &mut state);
        }

        let mut offspring = [0u64; MAX_POPULATION];
        for pair in 0..pairs {
            offspring[pair] = first_children[pair];
            offspring[pairs + pair] = second_children[pair];
        }
        for member in 0..n_pop {
            for gene in 0..n_var {
                if unit_random(&mut state) < 0.02 {
                    offspring[member] ^= 1u64 << gene;
                }
            }
            let cost = cost_of(offspring[member], n_var);
            if cost < best_cost {
                best_cost = cost;
            }
        }

        let mut merged = [0u64; MAX_POPULATION * 2];
        let mut merged_count = 0;
        for member in 0..n_pop {
            merged[merged_count] = population[member];
            merged_count += 1;
        }
        for member in 0..n_pop {
            merged[merged_count] = offspring[member];
            merged_count += 1;
        }
        for index in 1..merged_count {
            let selected = merged[index];
            let selected_cost = cost_of(selected, n_var);
            let mut insertion = index;
            while insertion > 0 && cost_of(merged[insertion - 1], n_var) > selected_cost {
                merged[insertion] = merged[insertion - 1];
                insertion -= 1;
            }
            merged[insertion] = selected;
        }
        for member in 0..n_pop {
            population[member] = merged[member];
        }
    }
    best_cost
}
