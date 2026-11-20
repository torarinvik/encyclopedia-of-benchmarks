module van_emde_boas_layout_search;

const usz VEB_MAX_HEIGHT = 4;
const usz VEB_MAX_NODES = 15;
const usz VEB_MAX_QUERIES = 4;
const usz VEB_MAX_WORDS = 41;
const usz VEB_MAX_PARSEABLE = 2 + VEB_MAX_QUERIES + 1;

fn void veb_fill_keys(long* keys, int heap, int low, int high) {
	if (low > high) return;
	int middle = low + (high - low) / 2;
	keys[heap] = middle;
	veb_fill_keys(keys, 2 * heap, low, middle - 1);
	veb_fill_keys(keys, 2 * heap + 1, middle + 1, high);
}

fn void veb_emit(long* order, int* used, int root, int height) {
	if (height == 1) {
		order[*used] = root;
		*used = *used + 1;
		return;
	}
	int top_height = height / 2;
	int bottom_height = height - top_height;
	veb_emit(order, used, root, top_height);
	int bottom_count = 1 << top_height;
	for (int offset = 0; offset < bottom_count; offset++)
		veb_emit(order, used, root * bottom_count + offset, bottom_height);
}

fn long van_emde_boas_layout_search(long* input, usz length,
		char* output, usz capacity) @export("van_emde_boas_layout_search") {
	if (input == null || length < 2 || length > VEB_MAX_PARSEABLE) return -1;
	long height_value = input[0];
	long query_value = input[1];
	if (height_value < 1 || height_value > (long)VEB_MAX_HEIGHT ||
		query_value < 0 || query_value > (long)VEB_MAX_QUERIES) return -1;
	int height = (int)height_value;
	int query_count = (int)query_value;
	if (length != (usz)(2 + query_count)) return -1;
	int node_count = (1 << height) - 1;
	for (int query = 0; query < query_count; query++)
		if (input[2 + query] < -1 || input[2 + query] > node_count) return -1;

	long[VEB_MAX_NODES] order = {0};
	long[VEB_MAX_NODES + 1] keys = {0};
	long[VEB_MAX_NODES + 1] slots = {0};
	long[VEB_MAX_WORDS] staged = {0};
	int used = 0;
	veb_emit(&order[0], &used, 1, height);
	veb_fill_keys(&keys[0], 1, 0, node_count - 1);
	for (int slot = 0; slot < node_count; slot++) slots[order[slot]] = slot;

	int out = 0;
	staged[out] = node_count; out++;
	for (int slot = 0; slot < node_count; slot++) { staged[out] = order[slot]; out++; }
	staged[out] = query_count; out++;
	for (int query = 0; query < query_count; query++) {
		long key = input[2 + query];
		int heap = 1;
		int path_start = out;
		out++;
		int path_length = 0;
		long found = -1;
		while (heap <= node_count) {
			staged[out] = slots[heap]; out++;
			path_length++;
			if (key == keys[heap]) { found = heap; break; }
			if (key < keys[heap]) heap = 2 * heap;
			else heap = 2 * heap + 1;
		}
		staged[path_start] = path_length;
		staged[out] = found; out++;
	}
	usz required = (usz)(out * 8);
	if (output == null || capacity < required) return -2;
	for (int word = 0; word < out; word++) {
		ulong bits = (ulong)staged[word];
		for (int byte = 0; byte < 8; byte++)
			output[(usz)word * 8 + (usz)byte] = (char)(bits >> (8 * byte));
	}
	return (long)required;
}
