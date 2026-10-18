package tabu_search

import "core:c"

MAX_CITIES :: 6
MAX_TOUR :: 7
MAX_CANDIDATES :: 32
MAX_OUTPUT_BYTES :: 36

store_i32_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u32(i32(value))
    for byte := 0; byte < 4; byte += 1 {
        output[offset+byte] = u8(bits & 255)
        bits >>= 8
    }
}

route_cost :: proc(route: [MAX_TOUR]i64, route_length: int,
        edge_cost: [MAX_CITIES*MAX_CITIES]i64) -> i64 {
    cost: i64 = 0
    for i := 0; i < route_length-1; i += 1 {
        cost += edge_cost[int(route[i])*MAX_CITIES+int(route[i+1])]
    }
    return cost
}

@(export)
tabu_search :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 3 || input_length > 19 do return -1
    if input[0] < 4 || input[0] > 6 || input[1] < 0 || input[1] > 8 || input[2] < 1 || input[2] > 3 do return -1
    cities, iterations, tabu_size := int(input[0]), int(input[1]), int(input[2])
    edge_count := cities*(cities-1)/2
    if int(input_length) != 3+edge_count do return -1
    edge_cost: [MAX_CITIES*MAX_CITIES]i64
    offset := 3
    for left := 0; left < cities; left += 1 {
        for right := left+1; right < cities; right += 1 {
            weight := input[offset]
            if weight < 1 || weight > 99 do return -1
            edge_cost[left*MAX_CITIES+right] = weight
            edge_cost[right*MAX_CITIES+left] = weight
            offset += 1
        }
    }
    solution: [MAX_TOUR]i64
    solution_length := 0
    visited: [MAX_CITIES]bool
    current := 0
    for !visited[current] {
        minimum: i64 = 10000
        best_node := current
        for node := 0; node < cities; node += 1 {
            if node != current && !visited[node] {
                weight := edge_cost[current*MAX_CITIES+node]
                if weight < minimum { minimum = weight; best_node = node }
            }
        }
        visited[current] = true
        solution[solution_length] = i64(current)
        solution_length += 1
        current = best_node
    }
    solution[solution_length] = 0
    solution_length += 1
    best_solution := solution
    best_cost := route_cost(solution, solution_length, edge_cost)

    tabu: [3][2]i64
    tabu_count := 0
    for iteration := 0; iteration < iterations; iteration += 1 {
        candidates: [MAX_CANDIDATES][MAX_TOUR]i64
        candidate_costs: [MAX_CANDIDATES]i64
        candidate_count := 0
        for first := 1; first < solution_length-1; first += 1 {
            for second := 1; second < solution_length-1; second += 1 {
                if first == second do continue
                candidate := solution
                candidate[first], candidate[second] = candidate[second], candidate[first]
                duplicate := false
                for prior := 0; prior < candidate_count; prior += 1 {
                    same := true
                    for i := 0; i < solution_length; i += 1 {
                        if candidates[prior][i] != candidate[i] { same = false }
                    }
                    if same { duplicate = true }
                }
                if !duplicate {
                    candidates[candidate_count] = candidate
                    candidate_costs[candidate_count] = route_cost(candidate, solution_length, edge_cost)
                    candidate_count += 1
                }
            }
        }
        // Stable insertion sort by cost.
        for i := 1; i < candidate_count; i += 1 {
            j := i
            for j > 0 && candidate_costs[j] < candidate_costs[j-1] {
                candidate_costs[j], candidate_costs[j-1] = candidate_costs[j-1], candidate_costs[j]
                candidates[j], candidates[j-1] = candidates[j-1], candidates[j]
                j -= 1
            }
        }
        for selected := 0; selected < candidate_count; selected += 1 {
            difference := -1
            for i := 0; i < solution_length; i += 1 {
                if candidates[selected][i] != solution[i] { difference = i; break }
            }
            if difference < 0 do continue
            new_city, old_city := candidates[selected][difference], solution[difference]
            is_tabu := false
            for i := 0; i < tabu_count; i += 1 {
                if (tabu[i][0] == new_city && tabu[i][1] == old_city) ||
                    (tabu[i][0] == old_city && tabu[i][1] == new_city) { is_tabu = true }
            }
            if is_tabu do continue
            tabu[tabu_count] = [2]i64{new_city, old_city}
            tabu_count += 1
            if tabu_count >= tabu_size {
                for i := 0; i < tabu_count-1; i += 1 { tabu[i] = tabu[i+1] }
                tabu_count -= 1
            }
            solution = candidates[selected]
            if candidate_costs[selected] < best_cost {
                best_cost = candidate_costs[selected]
                best_solution = solution
            }
            break
        }
    }
    staged: [MAX_OUTPUT_BYTES]u8
    store_i32_le(&staged[0], 0, i64(solution_length))
    for i := 0; i < solution_length; i += 1 { store_i32_le(&staged[0], 4*(i+1), best_solution[i]) }
    store_i32_le(&staged[0], 4*(solution_length+1), best_cost)
    output_bytes := (solution_length+2)*4
    if output == nil || output_capacity < c.size_t(output_bytes) do return -2
    for i := 0; i < output_bytes; i += 1 { output[i] = staged[i] }
    return i64(output_bytes)
}
