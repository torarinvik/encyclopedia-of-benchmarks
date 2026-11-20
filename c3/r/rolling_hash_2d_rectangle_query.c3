module rolling_hash_2d_rectangle_query;

const usz MAX_H = 32, MAX_W = 32, MAX_Q = 128;
const usz MAX_INPUT = 1540, MAX_OUTPUT = 1024;
const long MOD = 1000000007, ROW_BASE = 31, COL_BASE = 37;

fn void store_i64_le(char* output, usz offset, long value) {
	ulong bits = (ulong)value;
	for (usz byte = 0; byte < 8; ++byte) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long rolling_hash_2d_rectangle_query(long* input, usz length, char* output, usz capacity)
		@export("rolling_hash_2d_rectangle_query") {
	if (input == null || length < 3 || length > MAX_INPUT) return -1;
	long h_value = input[0], w_value = input[1], q_value = input[2];
	if (h_value < 1 || h_value > (long)MAX_H || w_value < 1 || w_value > (long)MAX_W ||
			q_value < 1 || q_value > (long)MAX_Q) return -1;
	usz h = (usz)h_value, w = (usz)w_value, q = (usz)q_value;
	if (length != 3 + h * w + 4 * q) return -1;
	usz query_offset = 3 + h * w;
	for (usz i = 0; i < h * w; ++i) if (input[3 + i] < 0 || input[3 + i] > 255) return -1;
	for (usz i = 0; i < q; ++i) {
		long r0 = input[query_offset + 4 * i], c0 = input[query_offset + 4 * i + 1];
		long r1 = input[query_offset + 4 * i + 2], c1 = input[query_offset + 4 * i + 3];
		if (r0 < 0 || r0 > r1 || r1 > h_value || c0 < 0 || c0 > c1 || c1 > w_value) return -1;
	}
	usz required = 8 * q;
	if (output == null || capacity < required) return -2;

	long[MAX_H + 1] row_power = {}, col_power = {};
	row_power[0] = 1; col_power[0] = 1;
	for (usz i = 1; i <= h; ++i) row_power[i] = row_power[i - 1] * ROW_BASE % MOD;
	for (usz j = 1; j <= w; ++j) col_power[j] = col_power[j - 1] * COL_BASE % MOD;
	long[(MAX_H + 1) * (MAX_W + 1)] prefix = {};
	for (usz r = 1; r <= h; ++r) {
		long row_hash = 0;
		for (usz c = 1; c <= w; ++c) {
			row_hash = (row_hash * COL_BASE + input[3 + (r - 1) * w + c - 1]) % MOD;
			usz at = r * (MAX_W + 1) + c;
			usz above = (r - 1) * (MAX_W + 1) + c;
			prefix[at] = (prefix[above] * ROW_BASE + row_hash) % MOD;
		}
	}
	char[MAX_OUTPUT] staged = {};
	for (usz i = 0; i < q; ++i) {
		usz r0 = (usz)input[query_offset + 4 * i], c0 = (usz)input[query_offset + 4 * i + 1];
		usz r1 = (usz)input[query_offset + 4 * i + 2], c1 = (usz)input[query_offset + 4 * i + 3];
		usz rh = r1 - r0, cw = c1 - c0;
		long value = prefix[r1 * (MAX_W + 1) + c1]
			- prefix[r0 * (MAX_W + 1) + c1] * row_power[rh] % MOD
			- prefix[r1 * (MAX_W + 1) + c0] * col_power[cw] % MOD
			+ prefix[r0 * (MAX_W + 1) + c0] * row_power[rh] % MOD * col_power[cw] % MOD;
		value %= MOD;
		if (value < 0) value += MOD;
		store_i64_le(&staged[0], 8 * i, value);
	}
	for (usz i = 0; i < required; ++i) output[i] = staged[i];
	return (long)required;
}
