export fn pfr_local_forward_decision(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
	if (input_opt == null or length != 2) return -1;
	const input = input_opt.?;
	const angle, const draw = .{ input[0], input[1] };
	if (angle < 0 or angle > 180_000_000 or draw < 0 or draw >= 1_000_000) return -1;
	const forward: i64 = if (angle >= 134_000_000 or 180 * draw < angle) 1 else 0;
	if (output_opt == null or capacity < 8) return -2;
	const bits: u64 = @bitCast(forward);
	const output = output_opt.?;
	for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
	return 8;
}
