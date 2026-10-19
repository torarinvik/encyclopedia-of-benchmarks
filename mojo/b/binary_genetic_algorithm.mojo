from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List
from std.math import exp

fn next_word(mut state: UInt64) -> UInt64:
    let mask = UInt128(0xFFFFFFFFFFFFFFFF)
    state = UInt64((UInt128(state) + UInt128(0x9E3779B97F4A7C15)) & mask)
    var value = state
    value = UInt64((UInt128(value ^ (value >> 30)) * UInt128(0xBF58476D1CE4E5B9)) & mask)
    value = UInt64((UInt128(value ^ (value >> 27)) * UInt128(0x94D049BB133111EB)) & mask)
    return value ^ (value >> 31)

fn bounded_draw(mut state: UInt64, bound: UInt64) -> UInt64:
    let threshold = UInt64(((UInt128(1) << 64) - UInt128(bound)) % UInt128(bound))
    while True:
        let value = next_word(state)
        if value >= threshold: return value % bound
    return 0

fn unit_draw(mut state: UInt64) -> Float64:
    return Float64(next_word(state) >> 11) / 9_007_199_254_740_992.0

fn bit_cost(candidate: UInt64, width: Int) -> Int:
    var total = 0
    for gene in range(width):
        if (candidate & (UInt64(1) << gene)) != 0: total += 1
    return total

fn choose_parent(probabilities: List[Float64], n: Int, total: Float64, mut state: UInt64) -> Int:
    let target = unit_draw(state) * total
    var cumulative: Float64 = 0.0
    for i in range(n):
        cumulative += probabilities[i]
        if target <= cumulative: return i
    return n - 1

fn cross_pair(first: UInt64, second: UInt64, width: Int, mut state: UInt64) -> (UInt64, UInt64):
    let kind = bounded_draw(state, 3)
    var child1: UInt64 = 0; var child2: UInt64 = 0
    if kind == 0:
        let cut = Int(bounded_draw(state, UInt64(width - 1))) + 1
        for gene in range(width):
            let bit = UInt64(1) << gene
            if gene < cut: child1 |= first & bit; child2 |= second & bit
            else: child1 |= second & bit; child2 |= first & bit
    elif kind == 1:
        var low = Int(bounded_draw(state, UInt64(width))) + 1
        var high = Int(bounded_draw(state, UInt64(width - 1))) + 1
        if high >= low: high += 1
        if high < low:
            let tmp = low; low = high; high = tmp
        for gene in range(width):
            let bit = UInt64(1) << gene
            let exchange = gene >= low and gene < high
            if exchange: child1 |= second & bit; child2 |= first & bit
            else: child1 |= first & bit; child2 |= second & bit
    else:
        for gene in range(width):
            let bit = UInt64(1) << gene
            if bounded_draw(state, 2) == 1: child1 |= first & bit; child2 |= second & bit
            else: child1 |= second & bit; child2 |= first & bit
    return (child1, child2)

@export("binary_genetic_algorithm")
fn binary_genetic_algorithm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or (length != 4 and length != 5): return -1
    let seed_value = input[0]; let nv = input[1]; let np = input[2]; let itv = input[3]
    if length != 4 or seed_value < 0 or nv < 2 or nv > 32 or np < 2 or np > 16 or (np % 2) != 0 or itv < 1 or itv > 32: return -1
    let width = Int(nv); let population_size = Int(np); let iterations = Int(itv)
    var state = UInt64(seed_value)
    var population = List[UInt64](capacity=population_size)
    var best_cost = width + 1
    for _ in range(population_size):
        var candidate: UInt64 = 0
        for gene in range(width): candidate |= bounded_draw(state, 2) << gene
        population.append(candidate)
        best_cost = min(best_cost, bit_cost(candidate, width))
    for _ in range(iterations):
        var costs = List[Int](capacity=population_size); var total_cost = 0
        for i in range(population_size):
            let cost = bit_cost(population[i], width); costs.append(cost); total_cost += cost
        let average = Float64(total_cost) / Float64(population_size)
        var probabilities = List[Float64](capacity=population_size); var ptotal: Float64 = 0.0
        for i in range(population_size):
            let scaled = Float64(costs[i]) / average if average != 0.0 else Float64(costs[i])
            let probability = exp(-scaled); probabilities.append(probability); ptotal += probability
        let pairs = population_size // 2
        var child1 = List[UInt64](capacity=pairs); var child2 = List[UInt64](capacity=pairs)
        for _ in range(pairs):
            let p1 = choose_parent(probabilities, population_size, ptotal, state)
            let p2 = choose_parent(probabilities, population_size, ptotal, state)
            let (c1, c2) = cross_pair(population[p1], population[p2], width, state)
            child1.append(c1); child2.append(c2)
        var offspring = List[UInt64](capacity=population_size)
        for i in range(pairs): offspring.append(child1[i])
        for i in range(pairs): offspring.append(child2[i])
        for member in range(population_size):
            for gene in range(width):
                if unit_draw(state) < 0.02: offspring[member] ^= UInt64(1) << gene
            best_cost = min(best_cost, bit_cost(offspring[member], width))
        var merged = List[UInt64](capacity=2 * population_size)
        for v in population: merged.append(v)
        for v in offspring: merged.append(v)
        for i in range(1, len(merged)):
            let value = merged[i]; let selected_cost = bit_cost(value, width); var j = i
            while j > 0 and bit_cost(merged[j - 1], width) > selected_cost:
                merged[j] = merged[j - 1]; j -= 1
            merged[j] = value
        for i in range(population_size): population[i] = merged[i]
    return Int64(best_cost)
