export fn x932_padding(values: ?[*]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(values==null||length<1||length>257)return -1;const input=values.?;if(input[0]<1||input[0]>64)return -1;for(1..length)|i|{if(input[i]<0 or input[i]>255)return -1;}const block:usize=@intCast(input[0]);const n=length-1;const pad=block-(n%block);const total=n+pad;if(total>capacity or output==null)return -2;for(0..n)|i|{output[i]=@intCast(input[i+1]);}for(n..total-1)|i|{output[i]=0;}output[total-1]=@intCast(pad);return @intCast(total);
}
