const MAX_OPERATIONS: usize = 32;
const MAX_INDEX: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_OPERATIONS;
const MAX_OUTPUT_WORKSPACE: usize = 128;

fn appendNumber(buffer: *[MAX_OUTPUT_WORKSPACE]u8, used: *usize, value: i64) void {
	var magnitude = value;
	if (magnitude < 0) {
		buffer[used.*] = '-';
		used.* += 1;
		magnitude = -magnitude;
	}
	var digits: [2]u8 = undefined;
	var digit_count: usize = 0;
	while (true) {
		digits[digit_count] = @intCast(@rem(magnitude, 10));
		digit_count += 1;
		magnitude = @divTrunc(magnitude, 10);
		if (magnitude == 0) break;
	}
	while (digit_count > 0) {
		digit_count -= 1;
		buffer[used.*] = @as(u8, '0') + digits[digit_count];
		used.* += 1;
	}
}

export fn number_container_system(
	input_opt: ?[*]const i64,
	length: usize,
	output_opt: ?[*]u8,
	capacity: usize,
) i64 {
	if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
	const input = input_opt.?[0..length];
	if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
	const operation_count: usize = @intCast(input[0]);
	if (length != 1 + 3 * operation_count) return -1;

	var slots: [MAX_INDEX]i64 = @splat(0);
	var present: [MAX_INDEX]bool = @splat(false);
	var buffer: [MAX_OUTPUT_WORKSPACE]u8 = undefined;
	var used: usize = 0;
	for (0..operation_count) |index| {
		const opcode = input[1 + 3 * index];
		const first = input[2 + 3 * index];
		const second = input[3 + 3 * index];
		if (opcode == 0) {
			if (first < 0 or first >= @as(i64, @intCast(MAX_INDEX)) or second < -100 or second > 100) return -1;
			slots[@intCast(first)] = second;
			present[@intCast(first)] = true;
		} else if (opcode == 1) {
			if (first < -100 or first > 100 or second != 0) return -1;
			var found: i64 = -1;
			for (0..MAX_INDEX) |slot| {
				if (present[slot] and slots[slot] == first) {
					found = @intCast(slot);
					break;
				}
			}
			if (used > 0) {
				buffer[used] = ',';
				used += 1;
			}
			appendNumber(&buffer, &used, found);
		} else {
			return -1;
		}
	}

	if (output_opt == null or used > capacity) return -2;
	const output = output_opt.?;
	for (0..used) |index| output[index] = buffer[index];
	return @intCast(used);
}
