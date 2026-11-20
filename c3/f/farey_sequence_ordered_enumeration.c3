module farey_sequence_ordered_enumeration;

fn long farey_count(long order) {
	long a = 0, b = 1, c = 1, d = order;
	long count = 1;
	while (true) {
		count += 1;
		if (c == d) break;
		long k = (order + b) / d;
		long next_c = k * c - a;
		long next_d = k * d - b;
		a = c;
		b = d;
		c = next_c;
		d = next_d;
	}
	return count;
}

fn void store_i64_le(char* output, usz offset, long value) {
	ulong bits = (ulong)value;
	for (usz byte = 0; byte < 8; byte += 1) {
		output[offset + byte] = (char)(bits & 0xff);
		bits >>= 8;
	}
}

fn long farey_sequence_ordered_enumeration(long* values, usz length, char* output,
	usz output_capacity) @export("farey_sequence_ordered_enumeration") {
	if (values == null || length != 1) return -1;
	long order = values[0];
	if (order < 1 || order > 32) return -1;
	long count = farey_count(order);
	usz required = (usz)(1 + 2 * count) * 8;
	if (output == null || output_capacity < required) return -2;

	store_i64_le(output, 0, count);
	store_i64_le(output, 8, 0);
	store_i64_le(output, 16, 1);
	long a = 0, b = 1, c = 1, d = order;
	usz position = 24;
	while (true) {
		store_i64_le(output, position, c);
		store_i64_le(output, position + 8, d);
		position += 16;
		if (c == d) break;
		long k = (order + b) / d;
		long next_c = k * c - a;
		long next_d = k * d - b;
		a = c;
		b = d;
		c = next_c;
		d = next_d;
	}
	return (long)required;
}
