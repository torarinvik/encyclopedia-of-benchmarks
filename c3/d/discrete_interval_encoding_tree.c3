module discrete_interval_encoding_tree;

const usz DIET_MAX_Q = 32;
const usz DIET_ARENA = 64;
const long DIET_MIN_KEY = -15;
const long DIET_MAX_KEY = 15;

struct DietNode { long lo; long hi; int left; int right; }

fn int diet_new(DietNode* nodes, int* used, long lo, long hi, int left, int right) {
	int index = *used;
	if (index >= (int)DIET_ARENA) return -1;
	nodes[index] = DietNode{lo, hi, left, right};
	*used = index + 1;
	return index;
}

fn int diet_pop_max(DietNode* nodes, int root, long* lo, long* hi) {
	if (nodes[root].right < 0) {
		*lo = nodes[root].lo;
		*hi = nodes[root].hi;
		return nodes[root].left;
	}
	nodes[root].right = diet_pop_max(nodes, nodes[root].right, lo, hi);
	return root;
}

fn int diet_pop_min(DietNode* nodes, int root, long* lo, long* hi) {
	if (nodes[root].left < 0) {
		*lo = nodes[root].lo;
		*hi = nodes[root].hi;
		return nodes[root].right;
	}
	nodes[root].left = diet_pop_min(nodes, nodes[root].left, lo, hi);
	return root;
}

fn void diet_max_interval(DietNode* nodes, int root, long* lo, long* hi) {
	while (nodes[root].right >= 0) root = nodes[root].right;
	*lo = nodes[root].lo;
	*hi = nodes[root].hi;
}

fn void diet_min_interval(DietNode* nodes, int root, long* lo, long* hi) {
	while (nodes[root].left >= 0) root = nodes[root].left;
	*lo = nodes[root].lo;
	*hi = nodes[root].hi;
}

fn int diet_insert(DietNode* nodes, int* used, int root, long key,
		int* interval_count, bool* changed) {
	if (root < 0) {
		*changed = true;
	*interval_count = *interval_count + 1;
		return diet_new(nodes, used, key, key, -1, -1);
	}
	if (key < nodes[root].lo) {
		if (key + 1 == nodes[root].lo) {
			nodes[root].lo = key;
			*changed = true;
			if (nodes[root].left >= 0) {
				long pred_lo, pred_hi;
				diet_max_interval(nodes, nodes[root].left, &pred_lo, &pred_hi);
				if (pred_hi + 1 == key) {
					nodes[root].left = diet_pop_max(nodes, nodes[root].left, &pred_lo, &pred_hi);
					nodes[root].lo = pred_lo;
					*interval_count = *interval_count - 1;
				}
			}
		} else {
			nodes[root].left = diet_insert(nodes, used, nodes[root].left, key, interval_count, changed);
		}
		return root;
	}
	if (key > nodes[root].hi) {
		if (key == nodes[root].hi + 1) {
			nodes[root].hi = key;
			*changed = true;
			if (nodes[root].right >= 0) {
				long succ_lo, succ_hi;
				diet_min_interval(nodes, nodes[root].right, &succ_lo, &succ_hi);
				if (key + 1 == succ_lo) {
					nodes[root].right = diet_pop_min(nodes, nodes[root].right, &succ_lo, &succ_hi);
					nodes[root].hi = succ_hi;
					*interval_count = *interval_count - 1;
				}
			}
		} else {
			nodes[root].right = diet_insert(nodes, used, nodes[root].right, key, interval_count, changed);
		}
		return root;
	}
	*changed = false;
	return root;
}

fn int diet_delete(DietNode* nodes, int* used, int root, long key,
		int* interval_count, bool* changed) {
	if (root < 0) { *changed = false; return root; }
	if (key < nodes[root].lo) {
		nodes[root].left = diet_delete(nodes, used, nodes[root].left, key, interval_count, changed);
		return root;
	}
	if (key > nodes[root].hi) {
		nodes[root].right = diet_delete(nodes, used, nodes[root].right, key, interval_count, changed);
		return root;
	}
	*changed = true;
	if (nodes[root].lo == nodes[root].hi) {
		*interval_count = *interval_count - 1;
		if (nodes[root].left < 0) return nodes[root].right;
		if (nodes[root].right < 0) return nodes[root].left;
		long pred_lo, pred_hi;
		nodes[root].left = diet_pop_max(nodes, nodes[root].left, &pred_lo, &pred_hi);
		nodes[root].lo = pred_lo;
		nodes[root].hi = pred_hi;
		return root;
	}
	if (key == nodes[root].lo) { nodes[root].lo = nodes[root].lo + 1; return root; }
	if (key == nodes[root].hi) { nodes[root].hi = nodes[root].hi - 1; return root; }
	int piece = diet_new(nodes, used, key + 1, nodes[root].hi, -1, nodes[root].right);
	nodes[root].hi = key - 1;
	nodes[root].right = piece;
	*interval_count = *interval_count + 1;
	return root;
}

fn bool diet_contains(DietNode* nodes, int root, long key) {
	while (root >= 0) {
		if (key < nodes[root].lo) root = nodes[root].left;
		else if (key > nodes[root].hi) root = nodes[root].right;
		else return true;
	}
	return false;
}

fn bool diet_valid(long* input, usz length, int* q_out) {
	if (input == null || length < 1 || length > 2 + 2 * DIET_MAX_Q) return false;
	if (input[0] < 0 || input[0] > (long)DIET_MAX_Q) return false;
	int q = (int)input[0];
	if (length != 1 + 2 * (usz)q) return false;
	for (int op = 0; op < q; op++) {
		long opcode = input[1 + 2 * (usz)op];
		long key = input[2 + 2 * (usz)op];
		if (opcode < 0 || opcode > 2 || key < DIET_MIN_KEY || key > DIET_MAX_KEY) return false;
	}
	*q_out = q;
	return true;
}

fn long discrete_interval_encoding_tree(long* input, usz length,
		char* output, usz capacity) @export("discrete_interval_encoding_tree") {
	int q = 0;
	if (!diet_valid(input, length, &q)) return -1;
	usz required = 8 * (usz)q;
	if ((required > 0 && output == null) || capacity < required) return -2;

	DietNode[DIET_ARENA] nodes = {0};
	int used = 0, root = -1, cardinality = 0, interval_count = 0;
	long[DIET_MAX_Q] staged = {0};
	for (int op = 0; op < q; op++) {
		long opcode = input[1 + 2 * (usz)op];
		long key = input[2 + 2 * (usz)op];
		bool changed = false;
		if (opcode == 0) {
			root = diet_insert(&nodes[0], &used, root, key, &interval_count, &changed);
			if (changed) cardinality++;
		} else if (opcode == 1) {
			root = diet_delete(&nodes[0], &used, root, key, &interval_count, &changed);
			if (changed) cardinality--;
		}
		long present = diet_contains(&nodes[0], root, key) ? 1 : 0;
		staged[op] = 64 * cardinality + 2 * interval_count + present;
	}
	for (int op = 0; op < q; op++) {
		ulong word = (ulong)staged[op];
		for (int byte = 0; byte < 8; byte++) output[8 * (usz)op + (usz)byte] = (char)(word >> (8 * byte));
	}
	return (long)required;
}
