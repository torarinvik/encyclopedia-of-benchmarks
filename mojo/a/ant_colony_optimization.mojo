from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List
from std.math import sqrt

fn ant_distance(cities: List[Int64], first: Int, second: Int) -> Float64:
    let dx = Float64(cities[first * 2] - cities[second * 2])
    let dy = Float64(cities[first * 2 + 1] - cities[second * 2 + 1])
    return sqrt(dx * dx + dy * dy)

fn ant_random(mut state: Int64) -> Float64:
    state = (state * 48271) % 2147483647
    return Float64(state) / 2147483647.0

fn ant_select_next(current: Int, visited: Int, cities: List[Int64], pheromones: List[Float64],
                   mut random_state: Int64) -> Int:
    var scores = List[Float64](length=3, fill=0.0)
    var total: Float64 = 0.0
    for city in range(3):
        if (visited & (1 << city)) != 0: continue
        let heuristic = 1.0 / ant_distance(cities, current, city)
        let squared = heuristic * heuristic
        let fifth = squared * squared * heuristic
        scores[city] = pheromones[current * 3 + city] * fifth
        total += scores[city]
    let roll = ant_random(random_state) * total
    var cumulative: Float64 = 0.0
    var fallback = 0
    for city in range(3):
        if (visited & (1 << city)) != 0: continue
        fallback = city
        cumulative += scores[city]
        if cumulative >= roll: return city
    return fallback

@export("ant_colony_optimization")
fn ant_colony_optimization(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    let invalid = -1.0e300
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 8 or input[0] < 1 or input[0] > 64 or input[1] < 1 or input[1] > 64:
        return invalid
    var cities = List[Int64](length=6, fill=0)
    for city in range(3):
        cities[city * 2] = input[2 + 2 * city]
        cities[city * 2 + 1] = input[3 + 2 * city]
        if cities[city * 2] < -100000 or cities[city * 2] > 100000 or cities[city * 2 + 1] < -100000 or cities[city * 2 + 1] > 100000:
            return invalid
        for prev in range(city):
            if cities[city * 2] == cities[prev * 2] and cities[city * 2 + 1] == cities[prev * 2 + 1]:
                return invalid
    let ants = Int(input[0])
    let iterations = Int(input[1])
    var pheromones = List[Float64](length=9, fill=1.0)
    var routes = List[Int](length=64 * 4, fill=0)
    var random_state: Int64 = 1
    var best_distance: Float64 = 1.0e300
    for iteration in range(iterations):
        for ant in range(ants):
            let route = ant * 4
            routes[route] = 0
            var current = 0
            var visited = 1
            for step in range(1, 3):
                current = ant_select_next(current, visited, cities, pheromones, random_state)
                routes[route + step] = current
                visited |= 1 << current
            routes[route + 3] = 0
            var distance: Float64 = 0.0
            for edge in range(3):
                distance += ant_distance(cities, routes[route + edge], routes[route + edge + 1])
            if distance < best_distance: best_distance = distance
        for from_city in range(3):
            for to_city in range(3):
                pheromones[from_city * 3 + to_city] *= 0.7
        for ant in range(ants):
            let route = ant * 4
            var distance: Float64 = 0.0
            for edge in range(3):
                distance += ant_distance(cities, routes[route + edge], routes[route + edge + 1])
            let deposit = 10.0 / distance
            for edge in range(3):
                let from_city = routes[route + edge]
                let to_city = routes[route + edge + 1]
                pheromones[from_city * 3 + to_city] += deposit
                pheromones[to_city * 3 + from_city] += deposit
    return best_distance
