package synchronous_round_push_relabel

import "core:c"

MAX_VERTICES :: 8
MAX_ARCS :: 24
MAX_INPUT_LENGTH :: c.size_t(77)
MAX_CAPACITY :: i64(15)

@(export)
synchronous_round_push_relabel :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT_LENGTH do return -1
	raw_n, raw_m, raw_source, raw_sink := input[0], input[1], input[2], input[3]
	if raw_n < 2 || raw_n > MAX_VERTICES || raw_m < 0 || raw_m > MAX_ARCS ||
		raw_source < 0 || raw_source >= raw_n || raw_sink < 0 || raw_sink >= raw_n ||
		raw_source == raw_sink || length != c.size_t(4 + 3 * raw_m) do return -1
	n, m := int(raw_n), int(raw_m)
	source, sink := int(raw_source), int(raw_sink)
	capacity: [MAX_VERTICES * MAX_VERTICES]i64
	for i := 0; i < m; i += 1 {
		offset := 4 + 3 * i
		u, v, amount := input[offset], input[offset + 1], input[offset + 2]
		if u < 0 || u >= raw_n || v < 0 || v >= raw_n || u == v || amount < 0 || amount > MAX_CAPACITY do return -1
		capacity[int(u) * MAX_VERTICES + int(v)] += amount
	}

	residual := capacity
	excess: [MAX_VERTICES]i64
	height: [MAX_VERTICES]int
	height[source] = n
	for v := 0; v < n; v += 1 {
		if v == source do continue
		forward, reverse := source * MAX_VERTICES + v, v * MAX_VERTICES + source
		amount := residual[forward]
		if amount != 0 {
			residual[forward] = 0
			residual[reverse] += amount
			excess[source] -= amount
			excess[v] += amount
		}
	}

	for {
		active: [MAX_VERTICES]int
		active_count := 0
		for v := 0; v < n; v += 1 {
			if v != source && v != sink && excess[v] > 0 && height[v] < n {
				active[active_count] = v
				active_count += 1
			}
		}
		if active_count == 0 do return excess[sink]

		change: [MAX_VERTICES]i64
		for ai := 0; ai < active_count; ai += 1 {
			u := active[ai]
			remaining := excess[u]
			for v := 0; v < n && remaining > 0; v += 1 {
				forward, reverse := u * MAX_VERTICES + v, v * MAX_VERTICES + u
				if residual[forward] > 0 && height[u] == height[v] + 1 {
					amount := remaining
					if residual[forward] < amount do amount = residual[forward]
					residual[forward] -= amount
					residual[reverse] += amount
					change[u] -= amount
					change[v] += amount
					remaining -= amount
				}
			}
		}

		next_excess: [MAX_VERTICES]i64
		next_height := height
		for v := 0; v < n; v += 1 do next_excess[v] = excess[v] + change[v]
		for ai := 0; ai < active_count; ai += 1 {
			u := active[ai]
			if next_excess[u] <= 0 do continue
			minimum := 2*MAX_VERTICES + 1
			for v := 0; v < n; v += 1 {
				if residual[u * MAX_VERTICES + v] > 0 && height[v] < minimum do minimum = height[v]
			}
			if minimum == 2*MAX_VERTICES + 1 do next_height[u] = n + 1
			else do next_height[u] = minimum + 1
		}
		for v := 0; v < n; v += 1 {
			excess[v] = next_excess[v]
			height[v] = next_height[v]
		}
	}
}
