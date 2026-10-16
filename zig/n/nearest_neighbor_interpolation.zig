const MAX_INPUT_LENGTH: usize = 2 + 16 * 16;

export fn nearest_neighbor_interpolation(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
	if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
	const rows_value = input[0];
	const columns_value = input[1];
	if (rows_value < 1 or rows_value > 16 or columns_value < 1 or columns_value > 16) return -1;
	const rows: usize = @intCast(rows_value);
	const columns: usize = @intCast(columns_value);
	const input_cells = rows * columns;
	if (length != 2 + input_cells) return -1;
	for (0..input_cells) |index| {
		const pixel = input[2 + index];
		if (pixel < 0 or pixel > 255) return -1;
	}

	const output_rows = 3 * rows / 2;
	const output_columns = 3 * columns / 2;
	const output_bytes = output_rows * output_columns;
	if (output == null or output_capacity < output_bytes) return -2;
	for (0..output_rows) |y| {
		const source_y = (4 * (y + 1) + 3) / 6 - 1;
		for (0..output_columns) |x| {
			const source_x = (4 * (x + 1) + 3) / 6 - 1;
			output[y * output_columns + x] = @intCast(input[2 + source_y * columns + source_x]);
		}
	}
	return @intCast(output_bytes);
}
