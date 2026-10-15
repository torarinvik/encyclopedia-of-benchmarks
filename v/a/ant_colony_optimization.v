module ant_colony_optimization

import math

const ant_limit = 64
const iteration_limit = 64
const invalid_result = -1.0e300

fn city_distance(cities []i64, first int, second int) f64 {
	dx := f64(cities[2 * first] - cities[2 * second])
	dy := f64(cities[2 * first + 1] - cities[2 * second + 1])
	return math.sqrt(dx * dx + dy * dy)
}

fn next_random_fraction(state &i64) f64 {
	unsafe {
		*state = (*state * 48271) % 2147483647
		return f64(*state) / 2147483647.0
	}
}

fn select_next_city(current int, visited []bool, cities []i64, pheromones []f64, random_state &i64) int {
	mut scores := []f64{len: 3, init: 0.0}
	mut total := f64(0.0)
	for city in 0 .. 3 {
		if visited[city] { continue }
		heuristic := 1.0 / city_distance(cities, current, city)
		squared := heuristic * heuristic
		fifth := squared * squared * heuristic
		scores[city] = pheromones[3 * current + city] * fifth
		total += scores[city]
	}
	roll := next_random_fraction(random_state) * total
	mut cumulative := f64(0.0)
	mut fallback := 0
	for city in 0 .. 3 {
		if visited[city] { continue }
		fallback = city
		cumulative += scores[city]
		if cumulative >= roll { return city }
	}
	return fallback
}

@[export: 'ant_colony_optimization']
pub fn ant_colony_optimization(input &i64, length usize) f64 {
	if length != 8 { return invalid_result }
	unsafe {
		ants := input[0]
		iterations := input[1]
		if ants < 1 || ants > ant_limit || iterations < 1 || iterations > iteration_limit { return invalid_result }
		mut cities := []i64{len: 6, init: 0}
		for index in 0 .. 6 {
			cities[index] = input[index + 2]
			if cities[index] < -100_000 || cities[index] > 100_000 { return invalid_result }
		}
		for first in 0 .. 3 {
			for second in 0 .. first {
				if cities[2 * first] == cities[2 * second] && cities[2 * first + 1] == cities[2 * second + 1] {
					return invalid_result
				}
			}
		}
		mut pheromones := []f64{len: 9, init: 1.0}
		mut routes := []int{len: ant_limit * 4, init: 0}
		mut random_state := i64(1)
		mut best_distance := f64(1.0e300)
		for _ in 0 .. int(iterations) {
			for ant in 0 .. int(ants) {
				route_start := ant * 4
				routes[route_start] = 0
				mut current := 0
				mut visited := []bool{len: 3, init: false}
				visited[0] = true
				for step in 1 .. 3 {
					current = select_next_city(current, visited, cities, pheromones, &random_state)
					routes[route_start + step] = current
					visited[current] = true
				}
				routes[route_start + 3] = 0
				mut distance := f64(0.0)
				for edge in 0 .. 3 {
					distance += city_distance(cities, routes[route_start + edge], routes[route_start + edge + 1])
				}
				if distance < best_distance { best_distance = distance }
			}
			for index in 0 .. 9 { pheromones[index] *= 0.7 }
			for ant in 0 .. int(ants) {
				route_start := ant * 4
				mut distance := f64(0.0)
				for edge in 0 .. 3 {
					distance += city_distance(cities, routes[route_start + edge], routes[route_start + edge + 1])
				}
				deposit := 10.0 / distance
				for edge in 0 .. 3 {
					from := routes[route_start + edge]
					to := routes[route_start + edge + 1]
					pheromones[3 * from + to] += deposit
					pheromones[3 * to + from] += deposit
				}
			}
		}
		return best_distance
	}
}
