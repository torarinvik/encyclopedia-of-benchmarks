module all_shortest_paths_unweighted;

const MAX_V = 16;
const MAX_E = 64;
const MAX_INPUT = 133;
const MAX_PATHS = 162;
const MAX_OUTPUT = 1296;

fn void enumerate(usz n, long target, bool* predecessor, bool* useful,
                  long* path, usz depth, char* staged, usz* used,
                  long* count, bool* overflow, long u) {
	if (overflow[0]) return;
	path[depth] = u;
	if (u == target) {
		if (count[0] >= MAX_PATHS || used[0] + depth + 2 > MAX_OUTPUT) { overflow[0] = true; return; }
		for (usz i = 0; i <= depth; i++) { staged[used[0]++] = (char)path[i]; }
		staged[used[0]++] = (char)255;
		count[0]++;
		return;
	}
	for (usz v = 0; v < n && !overflow[0]; v++) {
		if (useful[v] && predecessor[v * MAX_V + (usz)u]) {
			enumerate(n, target, predecessor, useful, path, depth + 1, staged, used, count, overflow, (long)v);
		}
	}
}

fn long all_shortest_paths_unweighted(long* input, usz length, char* output, usz capacity)
		@export("all_shortest_paths_unweighted") {
	if (input == null || length < 4 || length > MAX_INPUT) return -1;
	if (input[0] < 1 || input[0] > MAX_V || input[1] < 0 || input[1] > MAX_E) return -1;
	long n = input[0], m = input[1];
	if (input[2] < 0 || input[2] >= n || input[3] < 0 || input[3] >= n || length != 4 + 2 * (usz)m) return -1;
	long source = input[2], target = input[3];
	bool[MAX_V * MAX_V] adjacent = {};
	for (usz e = 0; e < (usz)m; e++) {
		long raw_u = input[4 + 2 * e], raw_v = input[5 + 2 * e];
		if (raw_u < 0 || raw_u >= n || raw_v < 0 || raw_v >= n || raw_u == raw_v) return -1;
		usz u = (usz)raw_u, v = (usz)raw_v;
		if (adjacent[u * MAX_V + v]) return -1;
		adjacent[u * MAX_V + v] = true;
		adjacent[v * MAX_V + u] = true;
	}
	long[MAX_V] distance = {};
	long[MAX_V] queue = {};
	bool[MAX_V * MAX_V] predecessor = {};
	for (usz v = 0; v < (usz)n; v++) distance[v] = -1;
	usz head = 0, tail = 0;
	distance[(usz)source] = 0;
	queue[tail++] = source;
	while (head < tail) {
		long u = queue[head++];
		for (usz v = 0; v < (usz)n; v++) {
			if (!adjacent[(usz)u * MAX_V + v]) continue;
			if (distance[v] < 0) { distance[v] = distance[(usz)u] + 1; queue[tail++] = (long)v; }
			if (distance[v] == distance[(usz)u] + 1) predecessor[v * MAX_V + (usz)u] = true;
		}
	}
	bool[MAX_V] useful = {};
	if (distance[(usz)target] >= 0) {
		long[MAX_V] stack = {};
		usz size = 0;
		useful[(usz)target] = true;
		stack[size++] = target;
		while (size > 0) {
			long v = stack[--size];
			for (usz u = 0; u < (usz)n; u++) {
				if (predecessor[(usz)v * MAX_V + u] && !useful[u]) { useful[u] = true; stack[size++] = (long)u; }
			}
		}
	}
	char[MAX_OUTPUT] staged = {};
	long[MAX_V] path = {};
	usz used = 0;
	long count = 0;
	bool overflow = false;
	if (distance[(usz)target] >= 0) enumerate((usz)n, target, predecessor, useful, path, 0, staged, &used, &count, &overflow, source);
	if (overflow) return -2;
	if (output == null || capacity < used) return -2;
	for (usz i = 0; i < used; i++) output[i] = staged[i];
	return count;
}
