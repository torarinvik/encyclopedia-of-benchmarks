module hash_join;

const usz MAX_ROWS = 8, HASH_CAPACITY = 17, MAX_INPUT = 19, MAX_OUTPUT = 64;

fn usz bucket_for(long key) {
	long remainder = key % (long)HASH_CAPACITY;
	if (remainder < 0) remainder += (long)HASH_CAPACITY;
	return (usz)remainder;
}

fn long hash_join(long* input, usz length, char* output, usz capacity)
		@export("hash_join") {
	if (input == null || length < 2 || length > MAX_INPUT) return -1;
	long left_value = input[0], right_value = input[1];
	if (left_value < 0 || left_value > (long)MAX_ROWS || right_value < 0 || right_value > (long)MAX_ROWS) return -1;
	usz left_count = (usz)left_value, right_count = (usz)right_value;
	if (length != 2 + left_count + right_count) return -1;

	bool build_left = left_count < right_count;
	usz build_count = build_left ? left_count : right_count;
	usz probe_count = build_left ? right_count : left_count;
	usz build_offset = build_left ? 2 : 2 + left_count;
	usz probe_offset = build_left ? 2 + left_count : 2;
	long[HASH_CAPACITY] keys = {};
	long[HASH_CAPACITY] heads = {}, tails = {};
	long[MAX_ROWS] next_row = {};
	bool[HASH_CAPACITY] occupied = {};
	char[MAX_OUTPUT] staged = {};
	for (usz slot = 0; slot < HASH_CAPACITY; ++slot) heads[slot] = tails[slot] = -1;
	for (usz row = 0; row < MAX_ROWS; ++row) next_row[row] = -1;

	for (usz row = 0; row < build_count; ++row) {
		long key = input[build_offset + row];
		usz slot = bucket_for(key);
		while (occupied[slot] && keys[slot] != key) slot = (slot + 1) % HASH_CAPACITY;
		if (!occupied[slot]) { occupied[slot] = true; keys[slot] = key; }
		if (tails[slot] < 0) heads[slot] = (long)row;
		else next_row[(usz)tails[slot]] = (long)row;
		tails[slot] = (long)row;
	}

	usz match_count = 0;
	for (usz probe_row = 0; probe_row < probe_count; ++probe_row) {
		long key = input[probe_offset + probe_row];
		usz slot = bucket_for(key);
		while (occupied[slot] && keys[slot] != key) slot = (slot + 1) % HASH_CAPACITY;
		if (!occupied[slot]) continue;
		for (long build_row = heads[slot]; build_row >= 0; build_row = next_row[(usz)build_row]) {
			usz left_id = build_left ? (usz)build_row : probe_row;
			usz right_id = build_left ? probe_row : (usz)build_row;
			staged[match_count++] = (char)((left_id << 4) | right_id);
		}
	}
	if (output == null || capacity < match_count) return -2;
	for (usz i = 0; i < match_count; ++i) output[i] = staged[i];
	return (long)match_count;
}
