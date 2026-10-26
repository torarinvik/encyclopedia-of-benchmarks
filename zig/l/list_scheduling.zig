const max_m:usize=8;const max_n:usize=32;const max_input:usize=34;
fn put64(out:[*]u8,pos:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|j|out[pos+j]=@truncate(b>>@intCast(8*j));}
export fn list_scheduling(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<3 or length>max_input)return -1;const input=input_opt.?;const m64=input[0];const n64=input[1];
 if(m64<1 or m64>8 or n64<1 or n64>32 or length!=2+@as(usize,@intCast(n64)))return -1
 const m:usize=@intCast(m64);const n:usize=@intCast(n64);for(0..n)|i|{if(input[2+i]<1 or input[2+i]>10000)return -1;}
 const bytes=8*(1+n+m);if(output_opt==null or capacity<bytes)return -2;const output=output_opt.?;
 var loads:[max_m]i64=@splat(0);var assignments:[max_n]i64=@splat(0);
 for(0..n)|i|{var best:usize=0;for(1..m)|j|{if(loads[j]<loads[best])best=j;}assignments[i]=@intCast(best);loads[best]+=input[2+i];}
 var span=loads[0];for(1..m)|j|{if(loads[j]>span)span=loads[j];}
 put64(output,0,span);for(0..n)|i|put64(output,8*(1+i),assignments[i]);for(0..m)|j|put64(output,8*(1+n+j),loads[j]);return @intCast(bytes);
}
