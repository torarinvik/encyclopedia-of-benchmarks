module minimum_mean_cycle_howard;

const usz MAX_N = 8, MAX_M = 16, MAX_INPUT = 51, OUTPUT_BYTES = 16;

fn bool all_reachable(usz n, bool* adjacent, bool reverse) {
	bool[MAX_N] seen = {};
	usz[MAX_N] queue = {};
	usz head = 0, tail = 0;
	seen[0] = true;
	queue[tail++] = 0;
	while (head < tail) {
		usz u = queue[head++];
		for (usz v = 0; v < n; ++v) {
			bool has_edge = reverse ? adjacent[v * MAX_N + u] : adjacent[u * MAX_N + v];
			if (has_edge && !seen[v]) { seen[v] = true; queue[tail++] = v; }
		}
	}
	for (usz v = 0; v < n; ++v) if (!seen[v]) return false;
	return true;
}

fn long gcd_positive(long a, long b) {
	while (b != 0) { long remainder = a % b; a = b; b = remainder; }
	return a;
}

fn long compare_ratio(long a_num, long a_den, long b_num, long b_den) {
	long left = a_num * b_den, right = b_num * a_den;
	return left < right ? -1 : left > right ? 1 : 0;
}

fn long compare_appraisal(usz a, usz b, usz* edge_to, long* edge_weight,
		long* value_num, long* value_den, long* bias_num) {
	usz a_to = edge_to[a], b_to = edge_to[b];
	long comparison = compare_ratio(value_num[a_to], value_den[a_to], value_num[b_to], value_den[b_to]);
	if (comparison != 0) return comparison;
	long a_bias = edge_weight[a] * value_den[a_to] - value_num[a_to] + bias_num[a_to];
	long b_bias = edge_weight[b] * value_den[b_to] - value_num[b_to] + bias_num[b_to];
	return compare_ratio(a_bias, value_den[a_to], b_bias, value_den[b_to]);
}

fn bool evaluate_policy(usz n, usz* edge_to, long* edge_weight, usz* policy,
		long* value_num, long* value_den, long* bias_num) {
	bool[MAX_N] assigned = {};
	for (usz start = 0; start < n; ++start) {
		if (assigned[start]) continue;
		long[MAX_N] local_position = {};
		for (usz v = 0; v < n; ++v) local_position[v] = -1;
		usz[MAX_N] path = {};
		usz path_length = 0, vertex = start;
		while (!assigned[vertex] && local_position[vertex] < 0) {
			local_position[vertex] = (long)path_length;
			path[path_length++] = vertex;
			vertex = edge_to[policy[vertex]];
		}
		usz prefix_length = path_length;
		if (!assigned[vertex]) {
			usz cycle_start = (usz)local_position[vertex];
			usz cycle_length = path_length - cycle_start;
			long cycle_weight = 0;
			usz head_position = cycle_start;
			for (usz i = cycle_start; i < path_length; ++i) {
				usz u = path[i];
				cycle_weight += edge_weight[policy[u]];
				if (path[i] < path[head_position]) head_position = i;
			}
			long absolute_weight = cycle_weight < 0 ? -cycle_weight : cycle_weight;
			long divisor = gcd_positive(absolute_weight, (long)cycle_length);
			long mean_num = cycle_weight / divisor;
			long mean_den = (long)cycle_length / divisor;
			usz head = path[head_position];
			for (usz i = cycle_start; i < path_length; ++i) {
				usz u = path[i];
				value_num[u] = mean_num;
				value_den[u] = mean_den;
				assigned[u] = true;
			}
			bias_num[head] = 0;
			usz current_position = head_position;
			while (true) {
				usz previous_position = current_position == cycle_start ? path_length - 1 : current_position - 1;
				usz previous = path[previous_position];
				if (previous == head) break;
				bias_num[previous] = edge_weight[policy[previous]] * mean_den
					- mean_num + bias_num[path[current_position]];
				current_position = previous_position;
			}
			prefix_length = cycle_start;
		}
		for (usz i = prefix_length; i > 0; --i) {
			usz u = path[i - 1];
			usz successor = edge_to[policy[u]];
			value_num[u] = value_num[successor];
			value_den[u] = value_den[successor];
			bias_num[u] = edge_weight[policy[u]] * value_den[successor]
				- value_num[successor] + bias_num[successor];
			assigned[u] = true;
		}
	}
	return true;
}

fn void store_i64_le(char* output, usz offset, long value) {
	ulong bits = (ulong)value;
	for (usz byte = 0; byte < 8; ++byte) {
		output[offset + byte] = (char)(bits & 255ul);
		bits >>= 8;
	}
}

fn long minimum_mean_cycle_howard(long* input, usz length, char* output, usz capacity)
		@export("minimum_mean_cycle_howard") {
	if (input == null || length < 2 || length > MAX_INPUT) return -1;
	long n_value = input[0], m_value = input[1];
	if (n_value < 1 || n_value > (long)MAX_N || m_value < 1 || m_value > (long)MAX_M) return -1;
	usz n = (usz)n_value, m = (usz)m_value;
	if (m > n * n || length != 2 + 3 * m) return -1;
	usz[MAX_M] edge_to = {};
	long[MAX_M] edge_weight = {};
	bool[MAX_N * MAX_N] adjacent = {};
	u8[MAX_N * MAX_M] outgoing = {};
	usz[MAX_N] degree = {}, policy = {};
	for (usz e = 0; e < m; ++e) {
		long u_value = input[2 + 3 * e], v_value = input[3 + 3 * e], weight = input[4 + 3 * e];
		if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || weight < -1000 || weight > 1000) return -1;
		usz u = (usz)u_value, v = (usz)v_value;
		usz slot = u * MAX_N + v;
		if (adjacent[slot]) return -1;
		adjacent[slot] = true;
		edge_to[e] = v; edge_weight[e] = weight;
		outgoing[u * MAX_M + degree[u]] = (u8)e;
		if (degree[u] == 0) policy[u] = e;
		degree[u] += 1;
	}
	if (!all_reachable(n, &adjacent[0], false) || !all_reachable(n, &adjacent[0], true)) return -1;
	if (output == null || capacity < OUTPUT_BYTES) return -2;

	usz policy_limit = 1;
	for (usz u = 0; u < n; ++u) policy_limit *= degree[u];
	long[MAX_N] value_num = {}, value_den = {}, bias_num = {};
	for (usz u = 0; u < n; ++u) value_den[u] = 1;
	bool converged = false;
	for (usz iteration = 0; iteration < policy_limit; ++iteration) {
		if (!evaluate_policy(n, &edge_to[0], &edge_weight[0], &policy[0],
				&value_num[0], &value_den[0], &bias_num[0])) return -1;
		usz[MAX_N] improved = {};
		bool changed = false;
		for (usz u = 0; u < n; ++u) {
			usz best = policy[u];
			for (usz j = 0; j < degree[u]; ++j) {
				usz candidate = (usz)outgoing[u * MAX_M + j];
				if (compare_appraisal(candidate, best, &edge_to[0], &edge_weight[0],
						&value_num[0], &value_den[0], &bias_num[0]) < 0) best = candidate;
			}
			improved[u] = best;
			if (best != policy[u]) changed = true;
		}
		if (!changed) { converged = true; break; }
		for (usz u = 0; u < n; ++u) policy[u] = improved[u];
	}
	if (!converged) return -1;
	usz best_vertex = 0;
	for (usz v = 1; v < n; ++v) {
		if (compare_ratio(value_num[v], value_den[v], value_num[best_vertex], value_den[best_vertex]) < 0) best_vertex = v;
	}
	long answer_num = value_num[best_vertex], answer_den = value_den[best_vertex];
	long absolute_num = answer_num < 0 ? -answer_num : answer_num;
	long divisor = gcd_positive(absolute_num, answer_den);
	answer_num /= divisor; answer_den /= divisor;
	char[OUTPUT_BYTES] staged = {};
	store_i64_le(&staged[0], 0, answer_num); store_i64_le(&staged[0], 8, answer_den);
	for (usz i = 0; i < OUTPUT_BYTES; ++i) output[i] = staged[i];
	return (long)OUTPUT_BYTES;
}
