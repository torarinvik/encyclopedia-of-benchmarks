module lower_bound_circulation_feasibility;

const usz MAX_N = 6, MAX_M = 8, MAX_INPUT = 35, NODE_CAP = 8;
const usz MATRIX_CAP = NODE_CAP * NODE_CAP;

fn long lower_bound_circulation_feasibility(long* input, usz length)
		@export("lower_bound_circulation_feasibility") {
	if (input == null || length < 2 || length > MAX_INPUT) return -1;
	long n_value = input[0], m_value = input[1];
	if (n_value < 1 || n_value > (long)MAX_N || m_value < 0 || m_value > (long)MAX_M) return -1;
	usz n = (usz)n_value, m = (usz)m_value;
	if (length != 2 + 4 * m) return -1;

	long[MATRIX_CAP] residual = {};
	long[MAX_N] balance = {};
	for (usz i = 0; i < m; ++i) {
		usz offset = 2 + 4 * i;
		long u_value = input[offset], v_value = input[offset + 1];
		long lower = input[offset + 2], upper = input[offset + 3];
		if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
				|| lower < 0 || upper < lower || upper > 2) return -1;
		usz u = (usz)u_value, v = (usz)v_value;
		residual[u * NODE_CAP + v] += upper - lower;
		balance[u] -= lower;
		balance[v] += lower;
	}

	usz source = n, sink = n + 1, node_count = n + 2;
	long demand = 0;
	for (usz v = 0; v < n; ++v) {
		if (balance[v] > 0) {
			residual[source * NODE_CAP + v] += balance[v];
			demand += balance[v];
		} else if (balance[v] < 0) {
			residual[v * NODE_CAP + sink] += -balance[v];
		}
	}

	long flow = 0;
	while (flow < demand) {
		long[NODE_CAP] parent = {};
		for (usz v = 0; v < node_count; ++v) parent[v] = -1;
		usz[NODE_CAP] queue = {};
		usz head = 0, tail = 0;
		parent[source] = (long)source;
		queue[tail++] = source;
		while (head < tail && parent[sink] < 0) {
			usz u = queue[head++];
			for (usz v = 0; v < node_count; ++v) {
				if (residual[u * NODE_CAP + v] > 0 && parent[v] < 0) {
					parent[v] = (long)u;
					queue[tail++] = v;
					if (v == sink) break;
				}
			}
		}
		if (parent[sink] < 0) break;
		long amount = demand - flow;
		usz v = sink;
		while (v != source) {
			usz u = (usz)parent[v];
			if (residual[u * NODE_CAP + v] < amount) amount = residual[u * NODE_CAP + v];
			v = u;
		}
		v = sink;
		while (v != source) {
			usz u = (usz)parent[v];
			residual[u * NODE_CAP + v] -= amount;
			residual[v * NODE_CAP + u] += amount;
			v = u;
		}
		flow += amount;
	}
	return flow == demand ? 1 : 0;
}
