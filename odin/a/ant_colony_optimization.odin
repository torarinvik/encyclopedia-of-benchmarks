package ant_colony_optimization

import "core:c"
import "core:math"

ANT_LIMIT :: 64
ITERATION_LIMIT :: 64
INVALID_RESULT :: f64(-1.0e300)

city_distance :: proc "contextless" (cities: [6]i64, first, second: int) -> f64 {
	dx := f64(cities[2*first] - cities[2*second])
	dy := f64(cities[2*first+1] - cities[2*second+1])
	return math.sqrt_f64(dx*dx + dy*dy)
}

next_random_fraction :: proc "contextless" (state: ^i64) -> f64 {
	state^ = (state^ * 48271) % 2147483647
	return f64(state^) / 2147483647.0
}

select_next_city :: proc "contextless" (current: int, visited: [3]bool, cities: [6]i64,
														pheromones: [9]f64, random_state: ^i64) -> int {
	scores: [3]f64
	for city := 0; city < 3; city += 1 {
		if visited[city] do continue
		heuristic := 1.0 / city_distance(cities, current, city)
		squared := heuristic * heuristic
		fifth := squared * squared * heuristic
		scores[city] = pheromones[3*current+city] * fifth
	}
	total := f64(0.0)
	for city := 0; city < 3; city += 1 {
		if !visited[city] do total += scores[city]
	}
	roll := next_random_fraction(random_state) * total
	cumulative := f64(0.0)
	fallback := 0
	for city := 0; city < 3; city += 1 {
		if visited[city] do continue
		fallback = city
		cumulative += scores[city]
		if cumulative >= roll do return city
	}
	return fallback
}

@(export)
ant_colony_optimization :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 8 do return INVALID_RESULT
	if input[0] < 1 || input[0] > ANT_LIMIT || input[1] < 1 || input[1] > ITERATION_LIMIT do return INVALID_RESULT
	cities: [6]i64
	for index := 0; index < 6; index += 1 {
		cities[index] = input[index+2]
		if cities[index] < -100_000 || cities[index] > 100_000 do return INVALID_RESULT
	}
	for first := 0; first < 3; first += 1 {
		for second := 0; second < first; second += 1 {
			if cities[2*first] == cities[2*second] && cities[2*first+1] == cities[2*second+1] do return INVALID_RESULT
		}
	}
	ant_count := int(input[0])
	iteration_count := int(input[1])
	pheromones: [9]f64
	for index := 0; index < 9; index += 1 { pheromones[index] = 1.0 }
	routes: [ANT_LIMIT*4]int
	random_state := i64(1)
	best_distance := f64(1.0e300)
	for iteration := 0; iteration < iteration_count; iteration += 1 {
		for ant := 0; ant < ant_count; ant += 1 {
			route_start := ant * 4
			routes[route_start] = 0
			current := 0
			visited := [3]bool{true, false, false}
			for step := 1; step < 3; step += 1 {
				current = select_next_city(current, visited, cities, pheromones, &random_state)
				routes[route_start+step] = current
				visited[current] = true
			}
			routes[route_start+3] = 0
			distance := f64(0.0)
			for edge := 0; edge < 3; edge += 1 {
				distance += city_distance(cities, routes[route_start+edge], routes[route_start+edge+1])
			}
			if distance < best_distance do best_distance = distance
		}
		for index := 0; index < 9; index += 1 { pheromones[index] *= 0.7 }
		for ant := 0; ant < ant_count; ant += 1 {
			route_start := ant * 4
			distance := f64(0.0)
			for edge := 0; edge < 3; edge += 1 {
				distance += city_distance(cities, routes[route_start+edge], routes[route_start+edge+1])
			}
			deposit := 10.0 / distance
			for edge := 0; edge < 3; edge += 1 {
				from := routes[route_start+edge]
				to := routes[route_start+edge+1]
				pheromones[3*from+to] += deposit
				pheromones[3*to+from] += deposit
			}
		}
	}
	return best_distance
}
