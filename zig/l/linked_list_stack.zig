const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_OPERATIONS;
const MAX_DEPTH: usize = 64;
const MAX_OUTPUT_BYTES: usize = 4 + 8 * MAX_OPERATIONS;

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
	const bits: u32 = @bitCast(value);
	for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn linked_list_stack(input_opt: ?[*]const i64, length: usize,
	output_opt: ?[*]u8, capacity: usize) i64 {
	if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
	const input = input_opt.?[0..length];
	if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_OPERATIONS))) return -1;

	const operation_count: usize = @intCast(input[0]);
	var node_values: [MAX_DEPTH]i32 = undefined;
	var node_next: [MAX_DEPTH]i32 = undefined;
	var records: [2 * MAX_OPERATIONS]i32 = undefined;
	var node_count: usize = 0;
	var query_count: usize = 0;
	var cursor: usize = 1;
	var top: i32 = -1;
	var stack_size: i32 = 0;
	for (0..operation_count) |_| {
		if (cursor >= length) return -1;
		const opcode = input[cursor];
		cursor += 1;
		if (opcode == 0) {
			if (cursor >= length) return -1;
			const value = input[cursor];
			cursor += 1;
			if (value < -2147483648 or value > 2147483647 or
				stack_size >= @as(i32, @intCast(MAX_DEPTH)) or node_count >= MAX_DEPTH) return -1;
			node_values[node_count] = @intCast(value);
			node_next[node_count] = top;
			top = @intCast(node_count);
			node_count += 1;
			stack_size += 1;
		} else if (opcode == 1) {
			if (stack_size == 0 or top < 0) return -1;
			records[2 * query_count] = 1;
			records[2 * query_count + 1] = node_values[@intCast(top)];
			query_count += 1;
			top = node_next[@intCast(top)];
			stack_size -= 1;
		} else if (opcode == 2) {
			records[2 * query_count] = 2;
			records[2 * query_count + 1] = stack_size;
			query_count += 1;
		} else if (opcode == 3) {
			records[2 * query_count] = 3;
			records[2 * query_count + 1] = if (stack_size == 0) 1 else 0;
			query_count += 1;
		} else {
			return -1;
		}
	}
	if (cursor != length) return -1;

	const output_bytes = 4 + 8 * query_count;
	if (output_opt == null or capacity < output_bytes) return -2;
	const output = output_opt.?;
	var buffer: [MAX_OUTPUT_BYTES]u8 = undefined;
	putI32Le(&buffer, 0, @intCast(query_count));
	for (0..2 * query_count) |index|
		putI32Le(&buffer, 4 + 4 * index, records[index]);
	for (0..output_bytes) |byte| output[byte] = buffer[byte];
	return @intCast(output_bytes);
}
