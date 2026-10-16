const MAX_INPUT_LENGTH: usize = 27;

fn writeF64Le(output: [*c]u8, offset: usize, value: f64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn gramMatrix(values: [*c]const i64, channels: usize, pixels: usize,
		part: usize, result: *[9]f64) void {
	const feature_count = channels * pixels;
	for (0..channels) |row| {
		for (0..channels) |column| {
			var dot: f64 = 0.0;
			for (0..pixels) |pixel| {
				const row_index = 3 + part * feature_count + row * pixels + pixel;
				const column_index = 3 + part * feature_count + column * pixels + pixel;
				const row_value = @as(f64, @floatFromInt(values[row_index])) / 1000.0;
				const column_value = @as(f64, @floatFromInt(values[column_index])) / 1000.0;
				dot += row_value * column_value;
			}
			result[row * channels + column] = dot / @as(f64, @floatFromInt(feature_count));
		}
	}
}

export fn gramian(values: [*c]const i64, length: usize,
		output: [*c]u8, output_capacity: usize) i64 {
	if (values == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
	const operation = values[0];
	const raw_channels = values[1];
	const raw_pixels = values[2];
	if ((operation != 0 and operation != 1) or raw_channels < 1 or raw_channels > 3 or
		raw_pixels < 1 or raw_pixels > 4) return -1;
	const channels: usize = @intCast(raw_channels);
	const pixels: usize = @intCast(raw_pixels);
	const feature_count = channels * pixels;
	const map_count: usize = if (operation == 1) 2 else 1;
	if (length != 3 + feature_count * map_count) return -1;
	for (3..length) |index| {
		if (values[index] < -1000 or values[index] > 1000) return -1;
	}
	const output_count: usize = if (operation == 1) 1 else channels * channels;
	const required = output_count * 8;
	if (output == null or output_capacity < required) return -2;

	var first: [9]f64 = @splat(0.0);
	gramMatrix(values, channels, pixels, 0, &first);
	if (operation == 0) {
		for (0..output_count) |index| writeF64Le(output, index * 8, first[index]);
	} else {
		var second: [9]f64 = @splat(0.0);
		gramMatrix(values, channels, pixels, 1, &second);
		var loss: f64 = 0.0;
		for (0..channels * channels) |index| {
			const difference = first[index] - second[index];
			loss += difference * difference;
		}
		writeF64Le(output, 0, loss);
	}
	return @intCast(required);
}
