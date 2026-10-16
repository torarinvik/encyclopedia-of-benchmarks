package graph_peripherality

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 56
INF :: i64(2305843009213693951)

put_i64_le :: proc "contextless" (output: [^]u8, word: c.size_t, value: i64) {
	bits := u64(value)
	for byte: c.size_t = 0; byte < 8; byte += 1 { output[word*8+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
graph_peripherality :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	n_value, edge_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES ||
		edge_value > n_value * (n_value - 1) || length != c.size_t(2 + 3 * edge_value) do return -1
	n, edge_count := int(n_value), int(edge_value)
	distance: [MAX_VERTICES * MAX_VERTICES]i64
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 { distance[i*MAX_VERTICES+j] = INF; if i == j { distance[i*MAX_VERTICES+j] = 0 } }
	}
	for edge := 0; edge < edge_count; edge += 1 {
		source_value, destination_value, weight := input[2+3*edge], input[3+3*edge], input[4+3*edge]
		if source_value < 0 || source_value >= n_value || destination_value < 0 || destination_value >= n_value ||
			source_value == destination_value || weight < 1 || weight > 1000000 do return -1
		source, destination := int(source_value), int(destination_value)
		cell := source*MAX_VERTICES+destination
		if distance[cell] != INF do return -1
		distance[cell] = weight
	}
	for middle := 0; middle < n; middle += 1 {
		for source := 0; source < n; source += 1 {
			if distance[source*MAX_VERTICES+middle] == INF do continue
			for destination := 0; destination < n; destination += 1 {
				first := distance[source*MAX_VERTICES+middle]
				second := distance[middle*MAX_VERTICES+destination]
				if second != INF && first+second < distance[source*MAX_VERTICES+destination] { distance[source*MAX_VERTICES+destination] = first+second }
			}
		}
	}
	if n > 1 {
		for source := 0; source < n; source += 1 {
			for destination := 0; destination < n; destination += 1 {
				if source != destination && distance[source*MAX_VERTICES+destination] == INF do return -1
			}
		}
	}
	peripheral, far := -1, -1
	peripheral_infinite, far_infinite, any_reachable := false, false, false
	best_eccentricity, best_farness: i64 = -1, -1
	if n == 1 { peripheral, far = 0, 0; best_eccentricity, best_farness = 0, 0 } else {
		for source := 0; source < n; source += 1 {
			found := false
			eccentricity, farness: i64 = 0, 0
			for destination := 0; destination < n; destination += 1 {
				value := distance[source*MAX_VERTICES+destination]
				if destination == source || value == INF || value == 0 { continue }
				found = true
				if value > eccentricity { eccentricity = value }
				farness += value
			}
			if found { any_reachable = true }
			infinite := !found
			if peripheral < 0 || (infinite && !peripheral_infinite) || (infinite == peripheral_infinite &&
				(infinite || eccentricity > best_eccentricity || (eccentricity == best_eccentricity && source < peripheral))) {
				peripheral, peripheral_infinite, best_eccentricity = source, infinite, eccentricity
			}
			if far < 0 || (infinite && !far_infinite) || (infinite == far_infinite &&
				(infinite || farness > best_farness || (farness == best_farness && source < far))) {
				far, far_infinite, best_farness = source, infinite, farness
			}
		}
		if !any_reachable { peripheral, far = -1, -1; best_eccentricity, best_farness = -1, -1 }
		else { if peripheral_infinite { best_eccentricity = -1 }; if far_infinite { best_farness = -1 } }
	}
	if output == nil || capacity < 32 do return -2
	put_i64_le(output, 0, i64(peripheral)); put_i64_le(output, 1, best_eccentricity)
	put_i64_le(output, 2, i64(far)); put_i64_le(output, 3, best_farness)
	return 32
}
