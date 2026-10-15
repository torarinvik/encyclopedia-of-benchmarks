fn put_f64_le(output: [*]u8, offset: usize, value: f64) void {
	const bits: u64 = @bitCast(value);
	for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}

export fn gaussian_elimination(input: [*c]const i64, length: usize,
	output: [*c]u8, capacity: usize) i64 {
	if (input == null or length < 1) return -1;
	if (input[0] < 2 or input[0] > 8) return -1;
	const n: usize = @intCast(input[0]);
	if (length != 1+n*n+n) return -1;
	var matrix = [_][9]f64{[_]f64{0} ** 9} ** 8;
	for (0..n) |row| {
		for (0..n) |col| {
			const value = input[1+row*n+col];
			if ((row == col and value != 32) or (row != col and value != 0 and value != -1)) return -1;
			if ((row+1 < col or col+1 < row) and value != 0) return -1;
			if (row != col and value != input[1+col*n+row]) return -1;
			matrix[row][col] = @floatFromInt(value);
		}
		const rhs = input[1+n*n+row];
		if (rhs < -100 or rhs > 100) return -1;
		matrix[row][n] = @floatFromInt(rhs);
	}
	if (output == null or capacity < n*8) return -2;
	for (0..n-1) |step| {
		for (step+1..n) |row| {
			const factor = matrix[row][step] / matrix[step][step];
			for (step..n+1) |col| matrix[row][col] -= factor * matrix[step][col];
		}
	}
	var solution = [_]f64{0} ** 8;
	var row = n;
	while (row > 0) {
		row -= 1;
		var sum: f64 = 0;
		for (row+1..n) |col| sum += matrix[row][col] * solution[col];
		solution[row] = (matrix[row][n] - sum) / matrix[row][row];
	}
	for (0..n) |i| put_f64_le(output, i*8, solution[i]);
	return @intCast(n*8);
}
