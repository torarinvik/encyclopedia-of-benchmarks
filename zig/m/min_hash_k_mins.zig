const max_input:usize=66;
fn put64(o:[*]u8,p:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|j|o[p+j]=@truncate(b>>@intCast(8*j));}
export fn min_hash_k_mins(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<3 or length>max_input)return -1;const in=input_opt.?;const nr=in[0];const kr=in[1];if(nr<1 or nr>16 or kr<1 or kr>4 or length!=2+@as(usize,@intCast(nr*kr)))return -1;const n:usize=@intCast(nr);const k:usize=@intCast(kr);for(0..n*k)|i|{if(in[2+i]<0 or in[2+i]>1000)return -1;}const bytes=8*k;if(output_opt==null or capacity<bytes)return -2;const out=output_opt.?;for(0..k)|col|{var best:usize=0;for(1..n)|row|{if(in[2+row*k+col]<in[2+best*k+col])best=row;}put64(out,8*col,@intCast(best));}return @intCast(bytes);
}
