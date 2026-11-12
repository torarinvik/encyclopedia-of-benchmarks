module minimum_mean_cycle_karp;

const usz MAX_N = 8, MAX_M = 16, MAX_INPUT = 51, OUTPUT_BYTES = 16;

fn void store_i64_le(char* output, usz offset, long value) {
	ulong bits = (ulong)value;
	for (usz byte = 0; byte < 8; ++byte) {
		output[offset + byte] = (char)(bits & 255ul);
		bits >>= 8;
	}
}

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

fn bool ratio_less(long a_num, long a_den, long b_num, long b_den) {
	return a_num * b_den < b_num * a_den;
}

fn long gcd_positive(long a, long b) {
	while (b != 0) { long remainder = a % b; a = b; b = remainder; }
	return a;
}

fn long minimum_mean_cycle_karp(long* input, usz length, char* output, usz capacity)
		@export("minimum_mean_cycle_karp") {
	if (input == null || length < 2 || length > MAX_INPUT) return -1;
	long n_value = input[0], m_value = input[1];
	if (n_value < 1 || n_value > (long)MAX_N || m_value < 1 || m_value > (long)MAX_M) return -1;
	usz n = (usz)n_value, m = (usz)m_value;
	if (m > n * n || length != 2 + 3 * m) return -1;
	usz[MAX_M] edge_from = {}, edge_to = {};
	long[MAX_M] edge_weight = {};
	bool[MAX_N * MAX_N] adjacent = {};
	for (usz e = 0; e < m; ++e) {
		long u_value = input[2 + 3 * e], v_value = input[3 + 3 * e], weight = input[4 + 3 * e];
		if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || weight < -1000 || weight > 1000) return -1;
		usz u = (usz)u_value, v = (usz)v_value;
		if (adjacent[u * MAX_N + v]) return -1;
		adjacent[u * MAX_N + v] = true;
		edge_from[e] = u; edge_to[e] = v; edge_weight[e] = weight;
	}
	if (!all_reachable(n, &adjacent[0], false) || !all_reachable(n, &adjacent[0], true)) return -1;
	if (output == null || capacity < OUTPUT_BYTES) return -2;

	long[MAX_N + 1][MAX_N] cost = {};
	bool[MAX_N + 1][MAX_N] reachable = {};
	reachable[0][0] = true;
	for (usz k = 1; k <= n; ++k) {
		for (usz e = 0; e < m; ++e) {
			usz u = edge_from[e], v = edge_to[e];
			if (!reachable[k - 1][u]) continue;
			long candidate = cost[k - 1][u] + edge_weight[e];
			if (!reachable[k][v] || candidate < cost[k][v]) { reachable[k][v] = true; cost[k][v] = candidate; }
		}
	}
	bool have_answer = false;
	long answer_num = 0, answer_den = 1;
	for (usz v = 0; v < n; ++v) {
		if (!reachable[n][v]) continue;
		bool have_local = false;
		long local_num = 0, local_den = 1;
		for (usz k = 0; k < n; ++k) {
			if (!reachable[k][v]) continue;
			long numerator = cost[n][v] - cost[k][v], denominator = (long)(n - k);
			if (!have_local || ratio_less(local_num, local_den, numerator, denominator)) {
				local_num = numerator; local_den = denominator; have_local = true;
			}
		}
		if (have_local && (!have_answer || ratio_less(local_num, local_den, answer_num, answer_den))) {
			answer_num = local_num; answer_den = local_den; have_answer = true;
		}
	}
	if (!have_answer) return -1;
	long absolute_num = answer_num < 0 ? -answer_num : answer_num;
	long divisor = gcd_positive(absolute_num, answer_den);
	answer_num /= divisor; answer_den /= divisor;
	char[OUTPUT_BYTES] staged = {};
	store_i64_le(&staged[0], 0, answer_num); store_i64_le(&staged[0], 8, answer_den);
	for (usz i = 0; i < OUTPUT_BYTES; ++i) output[i] = staged[i];
	return (long)OUTPUT_BYTES;
}
