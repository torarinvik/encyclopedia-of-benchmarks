/// Three-sample Java Hampel filter using its default threshold 3.0.
fn insertSorted(values: *[3]f64, size: *usize, value: f64) void {
	var position: usize = 0;
	while (position < size.* and values[position] < value) : (position += 1) {}
	var index = size.*;
	while (index > position) {
		values[index] = values[index - 1];
		index -= 1;
	}
	values[position] = value;
	size.* += 1;
}

fn removeSorted(values: *[3]f64, size: *usize, value: f64) void {
	var position: usize = 0;
	while (position < size.* and values[position] != value) : (position += 1) {}
	if (position == size.*) return;
	var index = position + 1;
	while (index < size.*) : (index += 1) values[index - 1] = values[index];
	size.* -= 1;
}

fn median(values: *[3]f64, size: usize) f64 {
	const middle = size / 2;
	if (size % 2 == 1) return values[middle];
	return 0.5 * (values[middle - 1] + values[middle]);
}

fn mad(values: *[3]f64, size: usize, center: f64) f64 {
	var deviations: [3]f64 = @splat(0);
	var deviation_count: usize = 0;
	for (0..size) |index| {
		insertSorted(&deviations, &deviation_count, @abs(values[index] - center));
	}
	return median(&deviations, deviation_count);
}

fn putI64(output: [*c]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn hampel_filter(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
	if (input == null or length < 1 or input[0] < 0 or input[0] > 128) return -1;
	const count: usize = @intCast(input[0]);
	if (length != count + 1) return -1;
	for (0..count) |index| {
		const sample = input[index + 1];
		if (sample < -1000 or sample > 1000) return -1;
	}
	if (capacity < count * 8 or (count > 0 and output == null)) return -2;

	var arrival: [3]f64 = @splat(0);
	var sorted: [3]f64 = @splat(0);
	var size: usize = 0;
	var oldest: usize = 0;
	for (0..count) |index| {
		const value: f64 = @floatFromInt(input[index + 1]);
		if (size == 3) removeSorted(&sorted, &size, arrival[oldest]);
		insertSorted(&sorted, &size, value);
		arrival[oldest] = value;
		oldest = (oldest + 1) % 3;

		const center = median(&sorted, size);
		const deviation = mad(&sorted, size, center);
		const distance = @abs(value - center);
		const filtered = if (distance > 3.0 * 1.4826 * deviation) center else value;
		putI64(output, index * 8, @intFromFloat(filtered));
	}
	return @intCast(count * 8);
}
