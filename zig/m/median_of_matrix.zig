const MAX_ROWS: usize = 16;
const MAX_CELLS: usize = 128;
const MAX_INPUT_WORDS: usize = 1 + MAX_ROWS + MAX_CELLS;

fn putI32Le(output: [*]u8, value: i32) void {
	const bits: u32 = @bitCast(value);
	for (0..4) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn median_of_matrix(input_opt: ?[*]const i64, length: usize,
	output_opt: ?[*]u8, capacity: usize) i64 {
	if (input_opt == null or length < 1 or length > MAX_INPUT_WORDS) return -1;
	const input = input_opt.?[0..length];
	if (input[0] < 0 or input[0] > MAX_ROWS) return -1;

	const row_count: usize = @intCast(input[0]);
	var cursor: usize = 1;
	var value_count: usize = 0;
	var values: [MAX_CELLS]i32 = undefined;
	for (0..row_count) |_| {
		if (cursor >= length) return -1;
		const row_length = input[cursor];
		cursor += 1;
		if (row_length == -1) continue;
		if (row_length < 0 or row_length > MAX_CELLS) return -1;
		const cells: usize = @intCast(row_length);
		if (cells > MAX_CELLS - value_count or cells > length - cursor) return -1;
		for (0..cells) |_| {
			const value = input[cursor];
			cursor += 1;
			if (value < -2147483648 or value > 2147483647) return -1;
			values[value_count] = @intCast(value);
			value_count += 1;
		}
	}
	if (cursor != length or value_count == 0) return -1;

	for (1..value_count) |index| {
		const value = values[index];
		var position = index;
		while (position > 0 and values[position - 1] > value) {
			values[position] = values[position - 1];
			position -= 1;
		}
		values[position] = value;
	}

	if (output_opt == null or capacity < 4) return -2;
	const output = output_opt.?;
	var buffer: [4]u8 = undefined;
	putI32Le(&buffer, values[(value_count - 1) / 2]);
	for (0..4) |byte| output[byte] = buffer[byte];
	return 4;
}
