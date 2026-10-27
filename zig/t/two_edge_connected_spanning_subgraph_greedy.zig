const MAX_INPUT:usize=59;
fn put(o:[*]u8,at:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|i|o[at+i]=@truncate(b>>@intCast(8*i));}
fn connected(n:usize,m:usize,u:*[28]usize,v:*[28]usize,on:*[28]bool,skip:isize)bool{var seen:[8]bool=@splat(false);var q:[8]usize=@splat(0);var head:usize=0;var tail:usize=1;q[0]=0;seen[0]=true;while(head<tail){const a=q[head];head+=1;for(0..m)|e|{if(!on[e] or @as(isize,@intCast(e))==skip)continue;var b:usize=8;if(u[e]==a)b=v[e] else if(v[e]==a)b=u[e];if(b<8 and !seen[b]){seen[b]=true;q[tail]=b;tail+=1;}}}for(0..n)|i|{if(!seen[i])return false;}return true;}
fn edgeConnected(n:usize,m:usize,u:*[28]usize,v:*[28]usize,on:*[28]bool)bool{if(!connected(n,m,u,v,on,-1))return false;for(0..m)|e|{if(on[e] and !connected(n,m,u,v,on,@intCast(e)))return false;}return true;}
export fn two_edge_connected_spanning_subgraph_greedy(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<2 or length>MAX_INPUT)return -1;const input=input_opt.?;const n0=input[0];const m0=input[1];if(n0<3 or n0>8 or m0<3 or m0>28 or length!=2+2*@as(usize,@intCast(m0)))return -1;const n:usize=@intCast(n0);const m:usize=@intCast(m0);
 var u:[28]usize=@splat(0);var v:[28]usize=@splat(0);var on:[28]bool=@splat(false);
 for(0..m)|i|{const a=input[2+2*i];const b=input[3+2*i];if(a<0 or a>=b or b>=n0)return -1;u[i]=@intCast(a);v[i]=@intCast(b);on[i]=true;for(0..i)|j|{if(u[i]==u[j] and v[i]==v[j])return -1;}}
 if(!edgeConnected(n,m,&u,&v,&on))return -1;for(0..m)|e|{on[e]=false;if(!edgeConnected(n,m,&u,&v,&on))on[e]=true;}
 var count:usize=0;for(0..m)|e|{if(on[e])count+=1;}const bytes=8*(1+2*count);if(output_opt==null or capacity<bytes)return -2;const output=output_opt.?;put(output,0,@intCast(count));var at:usize=8;
 for(0..n)|a|{for(a+1..n)|b|{for(0..m)|e|{if(on[e] and u[e]==a and v[e]==b){put(output,at,@intCast(a));put(output,at+8,@intCast(b));at+=16;}}}}
 return @intCast(bytes);
}
