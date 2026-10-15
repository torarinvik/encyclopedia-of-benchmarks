fn putF64Le(output: [*c]u8, offset: usize, value: f64) void {
	const bits: u64 = @bitCast(value)
	for (0..8) |byte| output[offset+byte]=@truncate(bits >> @intCast(8*byte));
}
fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
	const bits: u64 = @bitCast(value)
	for (0..8) |byte| output[offset+byte]=@truncate(bits >> @intCast(8*byte));
}

pub export fn exponential_moving_average_java_stream(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
	if (input==null or length<2 or input[1]<0 or input[1]>256 or length != 2+@as(usize,@intCast(input[1]))) return -1;
	if (input[0] < -1_000_000 or input[0] > 1_000_000) return -1;
	var mean:f64=@floatFromInt(input[0]);var variance:f64=0;
	for (0..@intCast(input[1])) |index| {
		const sample=input[index+2];if(sample < -1_000_000 or sample > 1_000_000)return -1;
		const value:f64=@floatFromInt(sample);const deviation=value-mean;
		mean += 0.25*deviation;
		variance=0.75*(variance+0.25*deviation*deviation);
	}
	if(output==null or capacity<24)return -2;
	putF64Le(output,0,mean);putF64Le(output,8,variance);putI64Le(output,16,input[1]);
	return 24;
}
