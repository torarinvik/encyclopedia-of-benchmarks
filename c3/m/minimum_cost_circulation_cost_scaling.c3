module minimum_cost_circulation_cost_scaling;

const usz MAX_N = 8, MAX_M = 10, MAX_ARCS = 2 * MAX_M, MAX_INPUT = 43;
const long COST_OFFSET = 81;

struct ResidualArc {
	usz from;
	usz to;
	usz reverse;
	long capacity;
	long cost;
}

fn long minimum_cost_circulation_cost_scaling(long* input, usz length)
		@export("minimum_cost_circulation_cost_scaling") {
	if (input == null || length < 2 || length > MAX_INPUT) return -1;
	long n_value = input[0], m_value = input[1];
	if (n_value < 1 || n_value > (long)MAX_N || m_value < 0 || m_value > (long)MAX_M) return -1;
	usz n = (usz)n_value, m = (usz)m_value;
	if (length != 2 + 4 * m) return -1;

	ResidualArc[MAX_ARCS] edges = {};
	long max_scaled_cost = 0;
	for (usz index = 0; index < m; ++index) {
		usz offset = 2 + 4 * index;
		long from_value = input[offset], to_value = input[offset + 1];
		long capacity = input[offset + 2], cost = input[offset + 3];
		if (from_value < 0 || from_value >= n_value || to_value < 0 || to_value >= n_value
				|| capacity < 0 || capacity > 2 || cost < -4 || cost > 4) return -1;
		usz from = (usz)from_value, to = (usz)to_value;
		long scaled_cost = cost * (long)(n + 1);
		usz forward = 2 * index, reverse = forward + 1;
		edges[forward] = ResidualArc{from, to, reverse, capacity, scaled_cost};
		edges[reverse] = ResidualArc{to, from, forward, 0, -scaled_cost};
		long magnitude = scaled_cost < 0 ? -scaled_cost : scaled_cost;
		if (magnitude > max_scaled_cost) max_scaled_cost = magnitude;
	}

	long epsilon = 1;
	while (epsilon < max_scaled_cost) epsilon *= 2;
	long[MAX_N] price = {};
	usz arc_count = 2 * m;
	while (epsilon > 1) {
		epsilon /= 2;
		long[MAX_N] excess = {};
		for (usz edge_index = 0; edge_index < arc_count; ++edge_index) {
			if (edges[edge_index].capacity <= 0) continue;
			usz from = edges[edge_index].from, to = edges[edge_index].to;
			long reduced_cost = edges[edge_index].cost + price[from] - price[to];
			if (reduced_cost < 0) {
				long amount = edges[edge_index].capacity;
				edges[edge_index].capacity = 0;
				edges[edges[edge_index].reverse].capacity += amount;
				excess[from] -= amount;
				excess[to] += amount;
			}
		}

		usz[MAX_N] queue = {};
		bool[MAX_N] queued = {};
		usz head = 0, tail = 0, queue_count = 0;
		for (usz vertex = 0; vertex < n; ++vertex) {
			if (excess[vertex] > 0) {
				queue[tail] = vertex;
				tail = (tail + 1) % n;
				queue_count += 1;
				queued[vertex] = true;
			}
		}

		while (queue_count > 0) {
			usz vertex = queue[head];
			head = (head + 1) % n;
			queue_count -= 1;
			queued[vertex] = false;
			while (excess[vertex] > 0) {
				usz admissible = MAX_ARCS;
				for (usz edge_index = 0; edge_index < arc_count; ++edge_index) {
					if (edges[edge_index].from != vertex || edges[edge_index].to == vertex
							|| edges[edge_index].capacity <= 0) continue;
					usz to = edges[edge_index].to;
					if (edges[edge_index].cost + price[vertex] - price[to] < 0) {
						admissible = edge_index;
						break;
					}
				}

				if (admissible < MAX_ARCS) {
					usz to = edges[admissible].to, reverse = edges[admissible].reverse;
					long amount = excess[vertex] < edges[admissible].capacity
						? excess[vertex] : edges[admissible].capacity;
					edges[admissible].capacity -= amount;
					edges[reverse].capacity += amount;
					long old_excess = excess[to];
					excess[vertex] -= amount;
					excess[to] += amount;
					if (old_excess <= 0 && excess[to] > 0 && !queued[to]) {
						queue[tail] = to;
						tail = (tail + 1) % n;
						queue_count += 1;
						queued[to] = true;
					}
				} else {
					bool has_exit = false;
					long best_price = 0;
					for (usz edge_index = 0; edge_index < arc_count; ++edge_index) {
						if (edges[edge_index].from != vertex || edges[edge_index].capacity <= 0) continue;
						usz to = edges[edge_index].to;
						long candidate = price[to] - edges[edge_index].cost - epsilon;
						if (!has_exit || candidate > best_price) {
							has_exit = true;
							best_price = candidate;
						}
					}
					if (!has_exit) return -1;
					price[vertex] = best_price;
				}
			}
		}
		for (usz vertex = 0; vertex < n; ++vertex) {
			if (excess[vertex] != 0) return -1;
		}
	}

	long total_cost = 0;
	for (usz index = 0; index < m; ++index) {
		long capacity = input[2 + 4 * index + 2];
		long cost = input[2 + 4 * index + 3];
		long flow = capacity - edges[2 * index].capacity;
		total_cost += flow * cost;
	}
	return total_cost + COST_OFFSET;
}
