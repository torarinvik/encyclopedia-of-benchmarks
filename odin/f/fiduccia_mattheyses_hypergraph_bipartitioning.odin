package fiduccia_mattheyses_hypergraph_bipartitioning

import "core:c"

MAX_VERTICES :: 8
MAX_NETS :: 12
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(112)

count_bits :: proc "contextless" (value_input: int) -> int {
	value := value_input
	count := 0
	for value != 0 {
		count += value & 1
		value >>= 1
	}
	return count
}

cut_size :: proc "contextless" (net_masks: ^[MAX_NETS]int, net_sizes: ^[MAX_NETS]int,
		net_count, partition: int) -> int {
	cut := 0
	for edge := 0; edge < net_count; edge += 1 {
		in_a := count_bits(net_masks[edge] & partition)
		if in_a > 0 && in_a < net_sizes[edge] do cut += 1
	}
	return cut
}

move_gain :: proc "contextless" (vertex, partition, net_count: int,
		net_masks: ^[MAX_NETS]int, net_sizes: ^[MAX_NETS]int) -> int {
	vertex_bit := 1 << vertex
	is_in_a := (partition & vertex_bit) != 0
	gain := 0
	for edge := 0; edge < net_count; edge += 1 {
		if (net_masks[edge] & vertex_bit) != 0 {
			before_a := count_bits(net_masks[edge] & partition)
			after_a := before_a + 1
			if is_in_a do after_a = before_a - 1
		before_cut := before_a > 0 && before_a < net_sizes[edge]
		after_cut := after_a > 0 && after_a < net_sizes[edge]
		if before_cut do gain += 1
		if after_cut do gain -= 1
		}
	}
	return gain
}

@(export)
fiduccia_mattheyses_hypergraph_bipartitioning :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	vertex_count_value, net_count_value, partition_value := input[0], input[1], input[2]
	if vertex_count_value < 4 || vertex_count_value > MAX_VERTICES || vertex_count_value % 2 != 0 ||
		net_count_value < 0 || net_count_value > MAX_NETS do return -1
	vertex_count, net_count := int(vertex_count_value), int(net_count_value)
	if partition_value < 0 || partition_value >= i64(1 << vertex_count) do return -1
	initial_partition := int(partition_value)
	if count_bits(initial_partition) != vertex_count / 2 do return -1

	var net_masks: [MAX_NETS]int
	var net_sizes: [MAX_NETS]int
	offset := 3
	for edge := 0; edge < net_count; edge += 1 {
		if offset >= int(length) do return -1
		degree_value := input[offset]
		if degree_value < 2 || degree_value > i64(vertex_count) do return -1
		degree := int(degree_value)
		if offset + 1 + degree > int(length) do return -1
		net_mask := 0
		previous_vertex := -1
		for item := 0; item < degree; item += 1 {
			vertex_value := input[offset+1+item]
			if vertex_value < 0 || vertex_value >= i64(vertex_count) do return -1
			vertex := int(vertex_value)
			if vertex <= previous_vertex do return -1
			previous_vertex = vertex
			net_mask |= 1 << vertex
		}
		net_masks[edge], net_sizes[edge] = net_mask, degree
		offset += 1 + degree
	}
	if offset != int(length) do return -1

	partition := initial_partition
	current_cut := cut_size(&net_masks, &net_sizes, net_count, partition)
	for pass := 0; pass <= net_count; pass += 1 {
		pass_start_cut := current_cut
		working_partition := partition
		working_a_size := count_bits(working_partition)
		working_cut := current_cut
		best_partition, best_cut := partition, current_cut
		var locked: [MAX_VERTICES]bool

		for move := 0; move < vertex_count; move += 1 {
			var bucket_counts: [2 * MAX_NETS + 1]int
			var buckets: [2 * MAX_NETS + 1][MAX_VERTICES]int
			for vertex := 0; vertex < vertex_count; vertex += 1 {
				if locked[vertex] do continue
				in_a := (working_partition & (1 << vertex)) != 0
				resulting_a_size := working_a_size + 1
				if in_a do resulting_a_size = working_a_size - 1
				if resulting_a_size < vertex_count / 2 - 1 || resulting_a_size > vertex_count / 2 + 1 do continue
				gain := move_gain(vertex, working_partition, net_count, &net_masks, &net_sizes)
				bucket := gain + net_count
				buckets[bucket][bucket_counts[bucket]] = vertex
				bucket_counts[bucket] += 1
			}

			selected_vertex := -1
			selected_balance := 1 << 30
			for bucket := 2 * net_count; bucket >= 0; bucket -= 1 {
				if bucket_counts[bucket] == 0 do continue
				for position := 0; position < bucket_counts[bucket]; position += 1 {
					vertex := buckets[bucket][position]
					in_a := (working_partition & (1 << vertex)) != 0
					resulting_a_size := working_a_size + 1
					if in_a do resulting_a_size = working_a_size - 1
					balance := 2 * resulting_a_size - vertex_count
					if balance < 0 do balance = -balance
					if selected_vertex < 0 || balance < selected_balance ||
						(balance == selected_balance && vertex < selected_vertex) {
						selected_vertex, selected_balance = vertex, balance
					}
				}
				if selected_vertex >= 0 do break
			}
			if selected_vertex < 0 do break

			locked[selected_vertex] = true
			working_partition ^= 1 << selected_vertex
			if (working_partition & (1 << selected_vertex)) != 0 {
				working_a_size += 1
			} else {
				working_a_size -= 1
			}
			working_cut = cut_size(&net_masks, &net_sizes, net_count, working_partition)
			if working_cut < best_cut { best_cut, best_partition = working_cut, working_partition }
		}

		if best_cut < pass_start_cut {
			partition, current_cut = best_partition, best_cut
		} else {
			break
		}
	}
	return i64((current_cut << 8) | partition)
}
