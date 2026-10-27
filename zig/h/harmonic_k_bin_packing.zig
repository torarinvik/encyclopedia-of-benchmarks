const max_n:usize=32;const max_k:usize=8;const max_input:usize=34;const capacity_per_bin:i64=10000;
fn store_i64_le(out:[*]u8,off:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[off+b]=@truncate(bits>>@intCast(8*b));}
export fn harmonic_k_bin_packing(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null||length<3||length>max_input)return -1;const input=input_opt.?;const k64=input[0];const n64=input[1];
 if(k64<3||k64>max_k||n64<1||n64>max_n||length!=2+@as(usize,@intCast(n64)))return -1;const k:usize=@intCast(k64);const n:usize=@intCast(n64);
 for(0..n)|i|if(input[2+i]<1||input[2+i]>capacity_per_bin)return -1;const bytes=8*(n+1);if(output_opt==null||capacity<bytes)return -2;const out=output_opt.?;
 var current:[max_k]i64=[_]i64{-1}**max_k;var remaining:[max_k]i64=[_]i64{0}**max_k;var assignment:[max_n]i64=[_]i64{0}**max_n;var bins:i64=0;
 for(0..n)|i|{const size=input[2+i];var kind=k-1;for(0..k-1)|c|{if(size*@as(i64,@intCast(c+2))>capacity_per_bin){kind=c;break;}}
  if(current[kind]<0||size>remaining[kind]){current[kind]=bins;bins+=1;remaining[kind]=capacity_per_bin;}assignment[i]=current[kind];remaining[kind]-=size;
 }
 store_i64_le(out,0,bins);for(0..n)|i|store_i64_le(out,8*(i+1),assignment[i]);return @intCast(bytes);
}
