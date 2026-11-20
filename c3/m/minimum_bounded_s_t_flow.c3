module minimum_bounded_s_t_flow;

const usz MAX_N = 6, MAX_M = 8, MAX_INPUT = 37, NODE_CAP = 8;

fn bool mbstf_feasible(long* input, usz n, usz m, usz source, usz sink, long flow_cap) {
	long[NODE_CAP * NODE_CAP] residual = {};
	long[MAX_N] balance = {};
	for (usz i = 0; i < m; ++i) {
		usz offset = 4 + 4 * i;
		usz u = (usz)input[offset], v = (usz)input[offset + 1];
		long lower = input[offset + 2], upper = input[offset + 3];
		residual[u * NODE_CAP + v] += upper - lower;
		balance[u] -= lower;
		balance[v] += lower;
	}
	residual[sink * NODE_CAP + source] += flow_cap;

	usz super_source = n, super_sink = n + 1, node_count = n + 2;
	long demand = 0;
	for (usz v = 0; v < n; ++v) {
		if (balance[v] > 0) {
			residual[super_source * NODE_CAP + v] += balance[v];
			demand += balance[v];
		} else if (balance[v] < 0) {
			residual[v * NODE_CAP + super_sink] += -balance[v];
		}
	}

	long flow = 0;
	while (flow < demand) {
		long[NODE_CAP] parent = {};
		for (usz v = 0; v < node_count; ++v) parent[v] = -1;
		usz[NODE_CAP] queue = {};
		usz head = 0, tail = 0;
		parent[super_source] = (long)super_source;
		queue[tail++] = super_source;
		while (head < tail && parent[super_sink] < 0) {
			usz u = queue[head++];
			for (usz v = 0; v < node_count; ++v) {
				if (residual[u * NODE_CAP + v] > 0 && parent[v] < 0) {
					parent[v] = (long)u;
					queue[tail++] = v;
					if (v == super_sink) break;
				}
			}
		}
		if (parent[super_sink] < 0) break;
		long amount = demand - flow;
		for (usz v = super_sink; v != super_source; v = (usz)parent[v]) {
			usz u = (usz)parent[v];
			if (residual[u * NODE_CAP + v] < amount) amount = residual[u * NODE_CAP + v];
		}
		for (usz v = super_sink; v != super_source; v = (usz)parent[v]) {
			usz u = (usz)parent[v];
			residual[u * NODE_CAP + v] -= amount;
			residual[v * NODE_CAP + u] += amount;
		}
		flow += amount;
	}
	return flow == demand;
}

fn long minimum_bounded_s_t_flow(long* input, usz length) @export("minimum_bounded_s_t_flow") {
	if (input == null || length < 4 || length > MAX_INPUT) return -1;
	long n_value = input[0], m_value = input[1];
	long source_value = input[2], sink_value = input[3];
	if (n_value < 2 || n_value > (long)MAX_N || m_value < 0 || m_value > (long)MAX_M) return -1;
	if (source_value < 0 || source_value >= n_value || sink_value < 0 ||
		sink_value >= n_value || source_value == sink_value) return -1;
	usz n = (usz)n_value, m = (usz)m_value;
	usz source = (usz)source_value, sink = (usz)sink_value;
	if (length != 4 + 4 * m) return -1;

	long upper_bound = 0;
	for (usz i = 0; i < m; ++i) {
		usz offset = 4 + 4 * i;
		long u = input[offset], v = input[offset + 1];
		long lower = input[offset + 2], upper = input[offset + 3];
		if (u < 0 || u >= n_value || v < 0 || v >= n_value || lower < 0 ||
			upper < lower || upper > 2) return -1;
		if ((usz)u == source && (usz)v != source) upper_bound += upper;
	}

	long low = 0, high = upper_bound + 1;
	while (low < high) {
		long middle = low + (high - low) / 2;
		if (mbstf_feasible(input, n, m, source, sink, middle)) high = middle;
		else low = middle + 1;
	}
	return low > upper_bound ? -2 : low;
}
