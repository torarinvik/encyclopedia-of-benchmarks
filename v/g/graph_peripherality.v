module graph_peripherality

const max_vertices = 8
const max_edges = 56
const infinity = i64(2305843009213693951)

fn put_i64_le(output &u8, word usize, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[word * 8 + usize(byte)] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'graph_peripherality']
pub fn graph_peripherality(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		n_value := input[0]
		edge_value := input[1]
		if n_value < 1 || n_value > max_vertices || edge_value < 0 || edge_value > max_edges ||
			edge_value > n_value * (n_value - 1) || length != usize(2 + 3 * edge_value) { return -1 }
		n := int(n_value)
		edge_count := int(edge_value)
		mut distance := [64]i64{}
		for i in 0 .. n { for j in 0 .. n { distance[i * max_vertices + j] = if i == j { 0 } else { infinity } } }
		for edge in 0 .. edge_count {
			source_value := input[2 + 3 * edge]
			destination_value := input[3 + 3 * edge]
			weight := input[4 + 3 * edge]
			if source_value < 0 || source_value >= n_value || destination_value < 0 || destination_value >= n_value ||
				source_value == destination_value || weight < 1 || weight > 1000000 { return -1 }
			source := int(source_value)
			destination := int(destination_value)
			cell := source * max_vertices + destination
			if distance[cell] != infinity { return -1 }
			distance[cell] = weight
		}
		for middle in 0 .. n {
			for source in 0 .. n {
				if distance[source * max_vertices + middle] == infinity { continue }
				for destination in 0 .. n {
					first := distance[source * max_vertices + middle]
					second := distance[middle * max_vertices + destination]
					if second != infinity && first + second < distance[source * max_vertices + destination] { distance[source * max_vertices + destination] = first + second }
				}
			}
		}
		if n > 1 {
			for source in 0 .. n {
				for destination in 0 .. n {
					if source != destination && distance[source * max_vertices + destination] == infinity { return -1 }
				}
			}
		}
		mut peripheral := -1
		mut far := -1
		mut peripheral_infinite := false
		mut far_infinite := false
		mut any_reachable := false
		mut best_eccentricity := i64(-1)
		mut best_farness := i64(-1)
		if n == 1 {
			peripheral = 0
			far = 0
			best_eccentricity = 0
			best_farness = 0
		} else {
			for source in 0 .. n {
				mut found := false
				mut eccentricity := i64(0)
				mut farness := i64(0)
				for destination in 0 .. n {
					value := distance[source * max_vertices + destination]
					if destination == source || value == infinity || value == 0 { continue }
					found = true
					if value > eccentricity { eccentricity = value }
					farness += value
				}
				if found { any_reachable = true }
				infinite := !found
				if peripheral < 0 || (infinite && !peripheral_infinite) || (infinite == peripheral_infinite &&
					(infinite || eccentricity > best_eccentricity || (eccentricity == best_eccentricity && source < peripheral))) {
					peripheral = source
					peripheral_infinite = infinite
					best_eccentricity = eccentricity
				}
				if far < 0 || (infinite && !far_infinite) || (infinite == far_infinite &&
					(infinite || farness > best_farness || (farness == best_farness && source < far))) {
					far = source
					far_infinite = infinite
					best_farness = farness
				}
			}
			if !any_reachable { peripheral = -1; far = -1; best_eccentricity = -1; best_farness = -1 }
			else { if peripheral_infinite { best_eccentricity = -1 }; if far_infinite { best_farness = -1 } }
		}
		if unsafe { output == nil } || capacity < 32 { return -2 }
		put_i64_le(output, 0, i64(peripheral))
		put_i64_le(output, 1, best_eccentricity)
		put_i64_le(output, 2, i64(far))
		put_i64_le(output, 3, best_farness)
		return 32
	}
}
