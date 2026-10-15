fn putF64Le(output: [*c]u8, offset: usize, value: f64) void {
	const bits:u64=@bitCast(value)
	for(0..8)|byte| output[offset+byte]=@truncate(bits>>@intCast(8*byte));
}

pub export fn euler_method_julia(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
	if(input==null or length!=3)return -1;
	if(input[0]<-8 or input[0]>8 or input[1]<1 or input[1]>16 or input[2]<1 or input[2]>4)return -1;
	const steps:usize=@intCast(input[1]);const required=16*steps;if(output==null or capacity<required)return -2;
	const h=1.0/@as(f64,@floatFromInt(@as(u64,1)<<@intCast(input[2])));
	var states=[_]f64{0}**16;var times=[_]f64{0}**16;states[0]=@floatFromInt(input[0]);
	for(0..steps-1)|i|{states[i+1]=states[i]+h*(states[i]+times[i]);times[i+1]=times[i]+h;}
	for(0..steps)|i|{putF64Le(output,8*i,states[i]);putF64Le(output,8*(steps+i),times[i]);}
	return @intCast(required);
}
