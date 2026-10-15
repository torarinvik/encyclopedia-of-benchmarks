const ANT_LIMIT: usize = 64;
const ITERATION_LIMIT: usize = 64;
const INVALID_RESULT: f64 = -1.0e300;

type Cities = [[i64; 2]; 3];
type Pheromones = [[f64; 3]; 3];

fn city_distance(cities: &Cities, first: usize, second: usize) -> f64 {
    let dx = cities[first][0] as f64 - cities[second][0] as f64;
    let dy = cities[first][1] as f64 - cities[second][1] as f64;
    (dx * dx + dy * dy).sqrt()
}

fn next_random_fraction(state: &mut i64) -> f64 {
    *state = (*state * 48_271) % 2_147_483_647;
    *state as f64 / 2_147_483_647.0
}

fn select_next_city(
    current: usize,
    visited: u32,
    cities: &Cities,
    pheromones: &Pheromones,
    random_state: &mut i64,
) -> usize {
    let mut scores = [0.0; 3];
    let mut total = 0.0;
    for city in 0..3 {
        if visited & (1 << city) != 0 { continue; }
        let heuristic = 1.0 / city_distance(cities, current, city);
        let squared = heuristic * heuristic;
        let fifth = squared * squared * heuristic;
        scores[city] = pheromones[current][city] * fifth;
        total += scores[city];
    }
    let roll = next_random_fraction(random_state) * total;
    let mut cumulative = 0.0;
    let mut fallback = 0;
    for city in 0..3 {
        if visited & (1 << city) != 0 { continue; }
        fallback = city;
        cumulative += scores[city];
        if cumulative >= roll { return city; }
    }
    fallback
}

#[no_mangle]
pub unsafe extern "C" fn ant_colony_optimization(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length != 8 { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=ANT_LIMIT as i64).contains(&values[0]) || !(1..=ITERATION_LIMIT as i64).contains(&values[1]) {
        return INVALID_RESULT;
    }
    let mut cities = [[0i64; 2]; 3];
    for city in 0..3 {
        cities[city] = [values[2 + 2 * city], values[3 + 2 * city]];
        if cities[city].iter().any(|&coordinate| !(-100_000..=100_000).contains(&coordinate)) {
            return INVALID_RESULT;
        }
        for previous in 0..city {
            if cities[city] == cities[previous] { return INVALID_RESULT; }
        }
    }

    let ant_count = values[0] as usize;
    let iteration_count = values[1] as usize;
    let mut pheromones = [[1.0; 3]; 3];
    let mut routes = [[0usize; 4]; ANT_LIMIT];
    let mut random_state = 1i64;
    let mut best_distance = f64::INFINITY;

    for _ in 0..iteration_count {
        for ant in 0..ant_count {
            routes[ant][0] = 0;
            let mut current = 0;
            let mut visited = 1u32;
            for step in 1..3 {
                current = select_next_city(current, visited, &cities, &pheromones, &mut random_state);
                routes[ant][step] = current;
                visited |= 1 << current;
            }
            routes[ant][3] = 0;
            let mut distance = 0.0;
            for edge in 0..3 {
                distance += city_distance(&cities, routes[ant][edge], routes[ant][edge + 1]);
            }
            if distance < best_distance { best_distance = distance; }
        }
        for row in &mut pheromones { for value in row { *value *= 0.7; } }
        for ant in 0..ant_count {
            let mut distance = 0.0;
            for edge in 0..3 {
                distance += city_distance(&cities, routes[ant][edge], routes[ant][edge + 1]);
            }
            let deposit = 10.0 / distance;
            for edge in 0..3 {
                let from = routes[ant][edge];
                let to = routes[ant][edge + 1];
                pheromones[from][to] += deposit;
                pheromones[to][from] += deposit;
            }
        }
    }
    best_distance
}
