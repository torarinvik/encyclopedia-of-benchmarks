const max_n:usize=32;const max_input:usize=35;
fn put64(o:[*]u8,p:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|j|o[p+j]=@truncate(b>>@intCast(8*j));}
export fn max_average_length_bounded_segment(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<4 or length>max_input)return -1;const input=input_opt.?;const n64=input[0];const l64=input[1];const u64=input[2];
 if(n64<1 or n64>32 or l64<1 or u64<l64 or u64>n64 or length!=3+@as(usize,@intCast(n64)))return -1;const n:usize=@intCast(n64);const lower:usize=@intCast(l64);const upper:usize=@intCast(u64);
 for(0..n)|i|{if(input[3+i] < -10000 or input[3+i]>10000)return -1;}if(output_opt==null or capacity<32)return -2;const output=output_opt.?;
 var best_sum:i64=0;var best_len:usize=1;var best_start:usize=0;var best_end:usize=0;var have=false;
 for(0..n)|start|{var sum:i64=0;const limit=@min(n,start+upper);for(start+1..limit+1)|end|{sum+=input[3+end-1];const size=end-start;if(size<lower)continue;const left=sum*@as(i64,@intCast(best_len));const right=best_sum*@as(i64,@intCast(size));
  const tie=size<best_len or (size==best_len and (start<best_start or (start==best_start and end<best_end)));
  if(!have or left>right or (left==right and tie)){best_sum=sum;best_len=size;best_start=start;best_end=end;have=true;}
 }}put64(output,0,best_sum);put64(output,8,@intCast(best_len));put64(output,16,@intCast(best_start));put64(output,24,@intCast(best_end));return 32;
}
