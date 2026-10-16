module graph_coloring;

const usz MAX_VERTICES = 8;
const usz MAX_COLORS = 4;
const usz MAX_VALIDATION_LENGTH = 11;
const usz OUTPUT_BYTES = 8;

fn long count_from(u8* masks, u8* colors, usz vertex_count, usz color_count, usz vertex) {
	if (vertex == vertex_count) return 1;
	long count = 0;
	for (usz color = 0; color < color_count; color++) {
		bool safe = true;
		for (usz prior = 0; prior < vertex; prior++) {
			if ((masks[vertex] & (u8)(1 << prior)) != 0 && (usz)colors[prior] == color) {
				safe = false;
				break;
			}
		}
		if (safe) {
			colors[vertex] = (u8)color;
			count += count_from(masks, colors, vertex_count, color_count, vertex + 1);
		}
	}
	return count;
}

fn long graph_coloring(long* input, usz length, char* output, usz capacity)
		@export("graph_coloring") {
	if (input == null || length < 2 || length > MAX_VALIDATION_LENGTH) return -1;
	long n64 = input[0], m64 = input[1];
	if (n64 < 1 || n64 > (long)MAX_VERTICES || m64 < 1 || m64 > (long)MAX_COLORS) return -1;
	usz n = (usz)n64, m = (usz)m64;
	if (length != n + 2) return -1;

	u8[MAX_VERTICES] masks = {0};
	u8[MAX_VERTICES] colors = {0};
	long mask_limit = 1 << n;
	for (usz vertex = 0; vertex < n; vertex++) {
		long row = input[2 + vertex];
		if (row < 0 || row >= mask_limit) return -1;
		masks[vertex] = (u8)row;
		if ((masks[vertex] & (u8)(1 << vertex)) != 0) return -1;
	}
	for (usz vertex = 0; vertex < n; vertex++) {
		for (usz neighbor = 0; neighbor < n; neighbor++) {
			bool edge = (masks[vertex] & (u8)(1 << neighbor)) != 0;
			bool reverse_edge = (masks[neighbor] & (u8)(1 << vertex)) != 0;
			if (edge != reverse_edge) return -1;
		}
	}
	if (output == null || capacity < OUTPUT_BYTES) return -2;
	ulong count = (ulong)count_from(&masks[0], &colors[0], n, m, 0);
	for (usz byte = 0; byte < OUTPUT_BYTES; byte++) output[byte] = (char)(count >> (8 * byte));
	return (long)OUTPUT_BYTES;
}
