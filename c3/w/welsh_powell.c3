module welsh_powell;

const usz MAX_VERTICES = 32;
const usz MAX_EDGE_PAIRS = 512;
const usz MAX_VALIDATION_LENGTH = 2 + 2 * MAX_EDGE_PAIRS + 1;
const usz OUTPUT_BYTES_PER_VERTEX = 8;

fn ulong vertex_bit(usz vertex) {
	return (ulong)1 << vertex;
}

fn void put_i64_le(char* output, usz offset, long value) {
	ulong bits = (ulong)value;
	for (usz byte = 0; byte < OUTPUT_BYTES_PER_VERTEX; byte++) {
		output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
	}
}

fn long welsh_powell(long* input, usz length, char* output, usz capacity)
		@export("welsh_powell") {
	if (input == null || length < 2 || length > MAX_VALIDATION_LENGTH) return -1;
	long n64 = input[0], edge_count64 = input[1];
	if (n64 < 0 || n64 > (long)MAX_VERTICES || edge_count64 < 0 || edge_count64 > (long)MAX_EDGE_PAIRS) return -1;
	usz n = (usz)n64, edge_count = (usz)edge_count64;
	if (length != 2 + 2 * edge_count) return -1;

	ulong[MAX_VERTICES] adjacency = {0};
	for (usz edge = 0; edge < edge_count; edge++) {
		long left64 = input[2 + 2 * edge], right64 = input[3 + 2 * edge];
		if (left64 < 0 || left64 >= n64 || right64 < 0 || right64 >= n64 || left64 == right64) return -1;
		usz left = (usz)left64, right = (usz)right64;
		adjacency[left] |= vertex_bit(right);
		adjacency[right] |= vertex_bit(left);
	}

	usz output_bytes = n * OUTPUT_BYTES_PER_VERTEX;
	if (output == null || capacity < output_bytes) return -2;

	usz[MAX_VERTICES] degrees = {0};
	usz[MAX_VERTICES] order = {0};
	long[MAX_VERTICES] colors = {0};
	for (usz vertex = 0; vertex < n; vertex++) {
		colors[vertex] = -1;
		order[vertex] = vertex;
		for (usz neighbor = 0; neighbor < n; neighbor++) {
			if ((adjacency[vertex] & vertex_bit(neighbor)) != 0) degrees[vertex]++;
		}
	}

	// Stable descending degree order keeps equal-degree vertices by index.
	for (usz index = 1; index < n; index++) {
		usz key = order[index], position = index;
		while (position > 0 && degrees[order[position - 1]] < degrees[key]) {
			order[position] = order[position - 1];
			position--;
		}
		order[position] = key;
	}

	ulong colored_vertices = 0;
	for (usz index = 0; index < n; index++) {
		usz vertex = order[index];
		if (colors[vertex] >= 0) continue;
		ulong used_colors = 0;
		for (usz neighbor = 0; neighbor < n; neighbor++) {
			if ((adjacency[vertex] & vertex_bit(neighbor)) != 0 && colors[neighbor] >= 0) {
				used_colors |= vertex_bit((usz)colors[neighbor]);
			}
		}
		usz color = 0;
		while ((used_colors & vertex_bit(color)) != 0) color++;
		colors[vertex] = (long)color;
		colored_vertices |= vertex_bit(vertex);
		for (usz other_index = 0; other_index < n; other_index++) {
			usz other = order[other_index];
			if (colors[other] < 0 && (adjacency[other] & colored_vertices) == 0) {
				colors[other] = (long)color;
				colored_vertices |= vertex_bit(other);
			}
		}
	}

	for (usz vertex = 0; vertex < n; vertex++) put_i64_le(output, vertex * OUTPUT_BYTES_PER_VERTEX, colors[vertex]);
	return (long)output_bytes;
}
