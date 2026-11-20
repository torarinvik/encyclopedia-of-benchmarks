module hsadelta_differential_compression;

const usz MAX_LEN = 32, MAX_BLOCKS = 16, MAX_WORDS = 114, MAX_BYTES = 912, MAX_INPUT = 68;
const long INSERT = 0, COPY = 1;

fn long block_hash(long* data, usz start, usz width) {
	long value = 0;
	for (usz i = 0; i < width; ++i) value = value * 257 + data[start + i] + 1;
	return value;
}
fn int suffix_cmp(long* hashes, usz count, usz a, usz b) {
	while (a < count && b < count) { if (hashes[a] != hashes[b]) return hashes[a] < hashes[b] ? -1 : 1; ++a; ++b; }
	if (a == count && b == count) return 0;
	return a == count ? -1 : 1;
}
fn int prefix_cmp(long* hashes, usz count, usz suffix, long* query, usz depth) {
	for (usz i = 0; i < depth; ++i) {
		if (suffix + i >= count) return -1;
		if (hashes[suffix + i] != query[i]) return hashes[suffix + i] < query[i] ? -1 : 1;
	}
	return 0;
}
fn void interval(usz* sa, usz count, long* hashes, long* query, usz depth, usz* first, usz* last) {
	usz lo = 0, hi = count;
	while (lo < hi) { usz mid = lo + (hi - lo) / 2; if (prefix_cmp(hashes, count, sa[mid], query, depth) < 0) lo = mid + 1; else hi = mid; }
	*first = lo; hi = count;
	while (lo < hi) { usz mid = lo + (hi - lo) / 2; if (prefix_cmp(hashes, count, sa[mid], query, depth) <= 0) lo = mid + 1; else hi = mid; }
	*last = lo;
}
fn usz best_depth(usz* sa, usz count, long* hashes, long* query, usz qcount) {
	usz lo = 0, hi = (count < qcount ? count : qcount) + 1;
	while (lo + 1 < hi) { usz mid = lo + (hi - lo) / 2, first, last; interval(sa, count, hashes, query, mid, &first, &last); if (first < last) lo = mid; else hi = mid; }
	return lo;
}
fn usz extend(long* ref, usz m, long* ver, usz n, usz source, usz target, usz floor, usz* out_source, usz* out_target) {
	usz length = 0;
	while (source + length < m && target + length < n && ref[source + length] == ver[target + length]) ++length;
	while (source > 0 && target > floor && ref[source - 1] == ver[target - 1]) { --source; --target; ++length; }
	*out_source = source; *out_target = target; return length;
}
fn bool find_at(long* ref, usz m, long* ver, usz n, usz p, usz* sa, usz count, long* hashes, usz target, usz floor, usz* out_source, usz* out_target, usz* out_length) {
	usz qcount = (n - target) / p;
	if (qcount == 0 || count == 0) return false;
	long[MAX_BLOCKS] query = {};
	for (usz i = 0; i < qcount; ++i) query[i] = block_hash(ver, target + i * p, p);
	usz depth = best_depth(sa, count, hashes, &query[0], qcount);
	if (depth == 0) return false;
	usz checked = depth > 1 ? depth - 1 : 1, first, last;
	interval(sa, count, hashes, &query[0], checked, &first, &last);
	bool found = false;
	for (usz rank = first; rank < last; ++rank) {
		usz source = sa[rank] * p, cs, ct;
		if (source + p > m) continue;
		usz length = extend(ref, m, ver, n, source, target, floor, &cs, &ct);
		if (length < p) continue;
		if (!found || length > *out_length || (length == *out_length && (ct < *out_target || (ct == *out_target && cs < *out_source)))) { found = true; *out_source = cs; *out_target = ct; *out_length = length; }
	}
	return found;
}
fn void store_i64(char* output, usz offset, long value) { ulong bits = (ulong)value; for (usz i = 0; i < 8; ++i) output[offset + i] = (char)(bits >> (8 * i)); }

fn long hsadelta_differential_compression(long* input, usz length, char* output, usz capacity)
		@export("hsadelta_differential_compression") {
	if (input == null || length < 3 || length > MAX_INPUT) return -1;
	long mv = input[0], nv = input[1], pv = input[2];
	if (mv < 0 || mv > (long)MAX_LEN || nv < 0 || nv > (long)MAX_LEN || pv < 2 || pv > 4) return -1;
	usz m = (usz)mv, n = (usz)nv, p = (usz)pv;
	if (length != 3 + m + n) return -1;
	long* ref = input + 3; long* ver = input + 3 + m;
	for (usz i = 0; i < m + n; ++i) if (input[3 + i] < 0 || input[3 + i] > 255) return -1;
	long[MAX_BLOCKS] hashes = {}; usz[MAX_BLOCKS] sa = {};
	usz count = m >= p ? (m - p) / p + 1 : 0;
	for (usz i = 0; i < count; ++i) { hashes[i] = block_hash(ref, i * p, p); sa[i] = i; }
	for (usz i = 1; i < count; ++i) { usz value = sa[i], j = i; while (j > 0 && (suffix_cmp(&hashes[0], count, value, sa[j - 1]) < 0 || (suffix_cmp(&hashes[0], count, value, sa[j - 1]) == 0 && value < sa[j - 1]))) { sa[j] = sa[j - 1]; --j; } sa[j] = value; }
	long[MAX_WORDS] tokens = {}; usz words = 0, cursor = 0, consumed = 0;
	while (cursor + p <= n) {
		bool found = false; usz bs = 0, bt = 0, bl = 0;
		usz scan_end = cursor + p - 1 < n - p ? cursor + p - 1 : n - p;
		for (usz target = cursor; target <= scan_end; ++target) { usz cs = 0, ct = 0, cl = 0;
			if (find_at(ref, m, ver, n, p, &sa[0], count, &hashes[0], target, consumed, &cs, &ct, &cl) && (!found || cl > bl || (cl == bl && (ct < bt || (ct == bt && cs < bs)))) { found = true; bs = cs; bt = ct; bl = cl; }
		}
		if (!found) { ++cursor; continue; }
		if (bt > consumed) { tokens[words++] = INSERT; tokens[words++] = (long)(bt - consumed); for (usz i = consumed; i < bt; ++i) tokens[words++] = ver[i]; }
		tokens[words++] = COPY; tokens[words++] = (long)bs; tokens[words++] = (long)bl; consumed = bt + bl; cursor = consumed;
	}
	if (consumed < n) { tokens[words++] = INSERT; tokens[words++] = (long)(n - consumed); for (usz i = consumed; i < n; ++i) tokens[words++] = ver[i]; }
	usz required = words * 8;
	if (required > 0 && (output == null || capacity < required)) return -2;
	for (usz i = 0; i < words; ++i) store_i64(output, 8 * i, tokens[i]);
	return (long)required;
}
