const N:usize=8;const M:usize=12;const P:usize=8;const H:usize=56;const MAX_INPUT:usize=99;
const Graph=struct{n:usize,m:usize,p:usize,u:[M]usize,v:[M]usize,plen:[P]usize,path:[P][N]usize};
fn parse(a:[*c]const i64,len:usize)?Graph{
 if(a==null||len<3||len>MAX_INPUT)return null;const n0=a[0];const m0=a[1];const p0=a[2];if(n0<2||n0>N||m0<1||m0>M||p0<1||p0>P)return null;const n:usize=@intCast(n0);const m:usize=@intCast(m0);const p:usize=@intCast(p0);var g=Graph{.n=n,.m=m,.p=p,.u=[_]usize{0}**M,.v=[_]usize{0}**M,.plen=[_]usize{0}**P,.path=[_][N]usize{[_]usize{0}**N}**P};var pos:usize=3;if(pos+2*m>len)return null;var seen=[_]bool{false}**(N*N);
 for(0..m)|e|{const x=a[pos];const y=a[pos+1];pos+=2;if(x<0||x>=n0||y<0||y>=n0||x==y)return null;const u:usize=@intCast(x);const v:usize=@intCast(y);const lo=@min(u,v);const hi=@max(u,v);const k=lo*N+hi;if(seen[k])return null;seen[k]=true;g.u[e]=u;g.v[e]=v;}
 for(0..p)|q|{if(pos+2>len)return null;const s=a[pos];const k0=a[pos+1];pos+=2;if(s<0||s>=n0||k0<1||k0>=n0)return null;const k:usize=@intCast(k0);if(pos+k>len)return null;g.plen[q]=k;var cur:usize=@intCast(s);var usedv=[_]bool{false}**N;var usede=[_]bool{false}**M;usedv[cur]=true;for(0..k)|j|{const e0=a[pos];pos+=1;if(e0<0||e0>=m0)return null;const e:usize=@intCast(e0);if(usede[e])return null;usede[e]=true;g.path[q][j]=e;if(g.u[e]==cur){cur=g.v[e];}else if(g.v[e]==cur){cur=g.u[e];}else{return null;}if(usedv[cur])return null;usedv[cur]=true;}}
 if(pos!=len)return null;return g;
}
fn put(out:[*c]u8,word:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[word*8+b]=@truncate(bits>>@intCast(8*b));}
export fn packet_routing_work_conserving_schedule(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 const parsed=parse(input,length) orelse return -1;const g=parsed;var pos=[_]usize{0}**P;var tt=[_]i64{0}**H;var te=[_]i64{0}**H;var tp=[_]i64{0}**H;var count:usize=0;var time:usize=0;
 while(true){var active=false;var chosen=[_]i32{-1}**M;for(0..g.p)|q|{if(pos[q]<g.plen[q]){active=true;const e=g.path[q][pos[q]];if(chosen[e]<0)chosen[e]=@intCast(q);}}if(!active)break;for(0..g.m)|e|{if(chosen[e]>=0){if(count>=H)return -1;tt[count]=@intCast(time);te[count]=@intCast(e);tp[count]=chosen[e];count+=1;pos[@intCast(chosen[e])]+=1;}}time+=1;if(time>N*P)return -1;}
 const words=2+3*count;const bytes=words*8;if(output==null||capacity<bytes)return -2;put(output,0,@intCast(time));put(output,1,@intCast(count));for(0..count)|i|{put(output,2+3*i,tt[i]);put(output,3+3*i,te[i]);put(output,4+3*i,tp[i]);}return @intCast(bytes);
}
