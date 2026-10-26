const max_n:usize=12;const max_input:usize=25;
fn put64(o:[*]u8,p:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|j|o[p+j]=@truncate(b>>@intCast(8*j));}
export fn smith_weighted_completion_time(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<3 or length>max_input)return -1;const input=input_opt.?;const n64=input[0];if(n64<1 or n64>12 or length!=1+2*@as(usize,@intCast(n64)))return -1
 const n:usize=@intCast(n64);var p:[max_n]i64=@splat(0);var w:[max_n]i64=@splat(0);var order:[max_n]i64=@splat(0);
 for(0..n)|i|{p[i]=input[1+2*i];w[i]=input[2+2*i];if(p[i]<1 or p[i]>10000 or w[i]<1 or w[i]>10000)return -1;order[i]=@intCast(i);}
 const bytes=8*(n+1);if(output_opt==null or capacity<bytes)return -2;const output=output_opt.?;
 for(1..n)|i|{const key=order[i];var j=i;while(j>0){const prev:usize=@intCast(order[j-1]);const k:usize=@intCast(key);const before=w[k]*p[prev]>w[prev]*p[k] or (w[k]*p[prev]==w[prev]*p[k] and k<prev);if(!before)break;order[j]=order[j-1];j-=1;}order[j]=key;}
 var elapsed:i64=0;var total:i64=0;for(0..n)|i|{const job:usize=@intCast(order[i]);elapsed+=p[job];total+=w[job]*elapsed;}
 put64(output,0,total);for(0..n)|i|put64(output,8*(i+1),order[i]);return @intCast(bytes);
}
