module kruskal_reconstruction_tree_bottleneck;

const usz MAX_N = 8, MAX_M = 16, MAX_Q = 8, MAX_TREE = 15, LEVELS = 4, MAX_INPUT = 67;

fn usz find_root(usz* parent, usz vertex) {
	usz root = vertex;
	while (parent[root] != root) root = parent[root];
	while (parent[vertex] != vertex) {
		usz next = parent[vertex];
		parent[vertex] = root;
		vertex = next;
	}
	return root;
}

fn usz tree_lca(usz source, usz destination, usz* depth, usz* ancestor) {
	if (depth[source] < depth[destination]) {
		usz temporary = source;
		source = destination;
		destination = temporary;
	}
	usz difference = depth[source] - depth[destination];
	usz bit = 0;
	while (difference > 0) {
		if ((difference & 1) != 0) source = ancestor[bit * MAX_TREE + source];
		difference >>= 1;
		bit += 1;
	}
	if (source == destination) return source;
	for (usz level = LEVELS; level > 0; --level) {
		usz index = level - 1;
		usz source_ancestor = ancestor[index * MAX_TREE + source];
		usz destination_ancestor = ancestor[index * MAX_TREE + destination];
		if (source_ancestor != destination_ancestor) {
			source = source_ancestor;
			destination = destination_ancestor;
		}
	}
	return ancestor[source];
}

fn long kruskal_reconstruction_tree_bottleneck(long* input, usz length)
		@export("kruskal_reconstruction_tree_bottleneck") {
	if (input == null || length < 3 || length > MAX_INPUT) return -1;
	long n_value = input[0], m_value = input[1], q_value = input[2];
	if (n_value < 1 || n_value > (long)MAX_N || m_value < 0 || m_value > (long)MAX_M
			|| q_value < 1 || q_value > (long)MAX_Q) return -1;
	usz n = (usz)n_value, m = (usz)m_value, q = (usz)q_value;
	usz query_start = 3 + 3 * m;
	if (length != query_start + 2 * q) return -1;

	usz[MAX_M] edge_u = {}, edge_v = {};
	long[MAX_M] edge_weight = {};
	for (usz edge = 0; edge < m; ++edge) {
		long u = input[3 + 3 * edge], v = input[4 + 3 * edge];
		long weight = input[5 + 3 * edge];
		if (u < 0 || u >= n_value || v < 0 || v >= n_value
				|| weight < 0 || weight > 1000000) return -1;
		edge_u[edge] = (usz)u;
		edge_v[edge] = (usz)v;
		edge_weight[edge] = weight;
	}
	for (usz query = 0; query < q; ++query) {
		long source = input[query_start + 2 * query];
		long destination = input[query_start + 2 * query + 1];
		if (source < 0 || source >= n_value || destination < 0 || destination >= n_value)
			return -1;
	}

	for (usz i = 1; i < m; ++i) {
		usz u = edge_u[i], v = edge_v[i];
		long weight = edge_weight[i];
		usz position = i;
		while (position > 0 && edge_weight[position - 1] > weight) {
			edge_u[position] = edge_u[position - 1];
			edge_v[position] = edge_v[position - 1];
			edge_weight[position] = edge_weight[position - 1];
			position -= 1;
		}
		edge_u[position] = u;
		edge_v[position] = v;
		edge_weight[position] = weight;
	}

	usz[MAX_N] dsu_parent = {}, dsu_size = {};
	long[MAX_N] component_tree = {};
	long[MAX_TREE] tree_parent = {}, tree_left = {}, tree_right = {}, tree_weight = {};
	for (usz node = 0; node < MAX_TREE; ++node) {
		tree_parent[node] = -1;
		tree_left[node] = -1;
		tree_right[node] = -1;
	}
	for (usz vertex = 0; vertex < n; ++vertex) {
		dsu_parent[vertex] = vertex;
		dsu_size[vertex] = 1;
		component_tree[vertex] = (long)vertex;
	}

	usz next_tree_node = n;
	for (usz edge = 0; edge < m; ++edge) {
		usz root_u = find_root(&dsu_parent[0], edge_u[edge]);
		usz root_v = find_root(&dsu_parent[0], edge_v[edge]);
		if (root_u == root_v) continue;
		long left = component_tree[root_u], right = component_tree[root_v];
		usz merge_node = next_tree_node++;
		tree_left[merge_node] = left;
		tree_right[merge_node] = right;
		tree_weight[merge_node] = edge_weight[edge];
		tree_parent[(usz)left] = (long)merge_node;
		tree_parent[(usz)right] = (long)merge_node;
		if (dsu_size[root_u] < dsu_size[root_v]) {
			usz temporary = root_u;
			root_u = root_v;
			root_v = temporary;
		}
		dsu_parent[root_v] = root_u;
		dsu_size[root_u] += dsu_size[root_v];
		component_tree[root_u] = (long)merge_node;
	}
	usz[MAX_TREE] depth = {};
	usz[LEVELS * MAX_TREE] ancestor = {};
	for (usz node = next_tree_node; node > 0; --node) {
		usz current = node - 1;
		if (tree_parent[current] < 0) {
			ancestor[current] = current;
		} else {
			usz parent = (usz)tree_parent[current];
			ancestor[current] = parent;
			depth[current] = depth[parent] + 1;
		}
	}
	for (usz level = 1; level < LEVELS; ++level)
		for (usz node = 0; node < next_tree_node; ++node)
			ancestor[level * MAX_TREE + node] =
				ancestor[(level - 1) * MAX_TREE + ancestor[(level - 1) * MAX_TREE + node]];

	long checksum = 0;
	for (usz query = 0; query < q; ++query) {
		usz source = (usz)input[query_start + 2 * query];
		usz destination = (usz)input[query_start + 2 * query + 1];
		long answer;
		if (source == destination) answer = 0;
		else if (find_root(&dsu_parent[0], source) != find_root(&dsu_parent[0], destination))
			answer = -1;
		else answer = tree_weight[tree_lca(source, destination, &depth[0], &ancestor[0])];
		checksum += (long)(query + 1) * (answer + 2);
	}
	return checksum;
}
