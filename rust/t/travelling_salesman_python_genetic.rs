fn integer_in_range(value: f64, minimum: i32, maximum: i32) -> bool {
    value.is_finite() && value >= minimum as f64 && value <= maximum as f64 && value.fract() == 0.0
}

unsafe extern "C" {
    fn rand() -> i32;
}

fn random_raw() -> usize {
    unsafe { rand() as usize }
}

fn random_unit() -> f64 {
    random_raw() as f64 / 2_147_483_647.0
}

fn random_index(upper_inclusive: usize) -> usize {
    random_raw() % (upper_inclusive + 1)
}

fn city_distance(cities: &[[i64; 2]; 2], left: usize, right: usize) -> f64 {
    let dx = (cities[left][0] - cities[right][0]) as f64;
    let dy = (cities[left][1] - cities[right][1]) as f64;
    (dx * dx + dy * dy).sqrt()
}

fn population_fitness(
    population: &[[usize; 3]; 8],
    population_size: usize,
    cities: &[[i64; 2]; 2],
    fitness: &mut [f64; 8],
    best_path: &mut [usize; 3],
    best_distance: &mut f64,
) {
    for person in 0..population_size {
        let mut total_distance = 0.0;
        for i in 0..2 {
            total_distance += city_distance(cities, population[person][i], population[person][i + 1]);
        }
        fitness[person] = 1.0 / total_distance;
        if total_distance < *best_distance {
            *best_path = population[person];
            *best_distance = total_distance;
        }
    }
}

fn repair_crossed_chromosome(
    chromosome: &mut [usize; 3],
    cities_list: &[usize; 1],
    segment_start: usize,
    segment_end: usize,
) {
    let mut has_duplicate = false;
    for i in 0..3 {
        for j in 0..i {
            if chromosome[i] == chromosome[j] { has_duplicate = true; }
        }
    }
    if !has_duplicate { return; }
    for segment_index in 0..=(segment_end - segment_start) {
        let current_index = segment_start + segment_index;
        let mut target_index = 0usize;
        for chromosome_index in 1..2 {
            if chromosome_index == current_index { continue; }
            if chromosome[chromosome_index] == chromosome[current_index] {
                target_index = chromosome_index;
                break;
            }
        }
        if target_index != 0 {
            let mut available = [cities_list[0]; 1];
            let mut available_count = 1usize;
            for city in chromosome.iter() {
                if available_count > 0 && *city == available[0] { available_count = 0; }
            }
            if available_count > 0 {
                let pick = random_index(available_count - 1);
                chromosome[target_index] = available[pick];
            }
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn travelling_salesman_python_genetic(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 8 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    if !integer_in_range(values[0], 2, 8) || (values[0] as i32) % 2 != 0
        || !integer_in_range(values[1], 0, 12)
    {
        return -1;
    }
    if !(0.0..=1.0).contains(&values[2]) || !(0.0..=1.0).contains(&values[3]) {
        return -1;
    }
    for i in 4..8 {
        if !integer_in_range(values[i], -16, 16) {
            return -1;
        }
    }
    let cities = [
        [values[4] as i64, values[5] as i64],
        [values[6] as i64, values[7] as i64],
    ];
    if cities[0] == cities[1] { return -1; }
    let population_size = values[0] as usize;
    let iterations = values[1] as usize;

    let cities_list = [1usize];
    let mut population = [[0usize; 3]; 8];
    for person in 0..population_size {
        population[person][0] = 0;
        let sampled_index = random_index(0); // Source random.sample([1], 1).
        population[person][1] = cities_list[sampled_index];
        population[person][2] = 0;
    }

    let mut fitness = [0.0; 8];
    let mut best_path = [0usize; 3];
    let mut best_distance = f64::INFINITY;
    population_fitness(&population, population_size, &cities, &mut fitness, &mut best_path, &mut best_distance);

    for _generation in 0..iterations {
        let mut total_probability = 0.0;
        for i in 0..population_size { total_probability += fitness[i]; }
        let mut probabilities = [0.0; 8];
        for i in 0..population_size { probabilities[i] = fitness[i] / total_probability; }

        let mut selected = population;
        for person in 0..population_size {
            let mut cumulative = 0.0;
            let draw = random_unit();
            for candidate in 0..population_size {
                cumulative += probabilities[candidate];
                if draw <= cumulative {
                    selected[person] = population[candidate];
                    break;
                }
            }
        }
        population = selected;

        let half = population_size / 2;
        for person in 0..half {
            let mut child_a = population[person];
            let mut child_b = population[person + half];
            if random_unit() <= values[2] {
                let mut first = random_index(2);
                let mut second = random_index(2);
                if first > second { std::mem::swap(&mut first, &mut second); }
                for i in first..=second { std::mem::swap(&mut child_a[i], &mut child_b[i]); }
                repair_crossed_chromosome(&mut child_a, &cities_list, first, second);
                repair_crossed_chromosome(&mut child_b, &cities_list, first, second);
            }
            population[person] = child_a;
            population[person + half] = child_b;
        }

        for person in 0..population_size {
            let mut chromosome = population[person];
            if random_unit() <= values[3] {
                let first = random_index(0) + 1;
                let second = random_index(0) + 1;
                chromosome.swap(first, second);
            }
            population[person] = chromosome;
        }
        population_fitness(&population, population_size, &cities, &mut fitness, &mut best_path, &mut best_distance);
    }

    let staged = [3.0, best_path[0] as f64, best_path[1] as f64, best_path[2] as f64, best_distance];
    if output.is_null() || output_capacity < staged.len() {
        return -2;
    }
    for i in 0..staged.len() {
        unsafe { *output.add(i) = staged[i]; }
    }
    staged.len() as i64
}
