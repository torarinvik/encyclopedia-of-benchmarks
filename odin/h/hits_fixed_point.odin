package hits_fixed_point

import "core:c"

MAX_VERTICES :: 16
MAX_EDGES :: 64
MAX_ITERATIONS :: 32
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(132)
SCORE_SCALE :: i64(1_000_000)

@(export)
hits_fixed_point :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1

	n_value := input[0]
	m_value := input[1]
	k_value := input[2]
	if n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES do return -1
	if k_value < 0 || k_value > MAX_ITERATIONS do return -1

	n := int(n_value)
	m := int(m_value)
	iterations := int(k_value)
	if length != c.size_t(3 + 2 * m) do return -1

	var sources: [MAX_EDGES]int
	var targets: [MAX_EDGES]int
	var seen: [MAX_VERTICES * MAX_VERTICES]bool
	for edge := 0; edge < m; edge += 1 {
		source_value := input[3 + 2 * edge]
		target_value := input[4 + 2 * edge]
		if source_value < 0 || source_value >= n_value || target_value < 0 || target_value >= n_value do return -1
		if source_value == target_value do return -1
		source := int(source_value)
		target := int(target_value)
		slot := source * MAX_VERTICES + target
		if seen[slot] do return -1
		seen[slot] = true
		sources[edge] = source
		targets[edge] = target
	}

	var hubs: [MAX_VERTICES]i64
	var authorities: [MAX_VERTICES]i64
	for vertex := 0; vertex < n; vertex += 1 { hubs[vertex] = SCORE_SCALE }

	for iteration := 0; iteration < iterations; iteration += 1 {
		var raw_authorities: [MAX_VERTICES]i64
		for edge := 0; edge < m; edge += 1 { raw_authorities[targets[edge]] += hubs[sources[edge]] }
		authority_total := i64(0)
		for vertex := 0; vertex < n; vertex += 1 { authority_total += raw_authorities[vertex] }
		if authority_total == 0 {
			for vertex := 0; vertex < n; vertex += 1 { authorities[vertex] = 0 }
		} else {
			for vertex := 0; vertex < n; vertex += 1 { authorities[vertex] = raw_authorities[vertex] * SCORE_SCALE / authority_total }
		}

		var raw_hubs: [MAX_VERTICES]i64
		for edge := 0; edge < m; edge += 1 { raw_hubs[sources[edge]] += authorities[targets[edge]] }
		hub_total := i64(0)
		for vertex := 0; vertex < n; vertex += 1 { hub_total += raw_hubs[vertex] }
		if hub_total == 0 {
			for vertex := 0; vertex < n; vertex += 1 { hubs[vertex] = 0 }
		} else {
			for vertex := 0; vertex < n; vertex += 1 { hubs[vertex] = raw_hubs[vertex] * SCORE_SCALE / hub_total }
		}
	}

	result := i64(0)
	for vertex := 0; vertex < n; vertex += 1 {
		result += i64(vertex + 1) * (authorities[vertex] + 65537 * hubs[vertex])
	}
	return result
}
