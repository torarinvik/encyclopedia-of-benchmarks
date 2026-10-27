const N:usize=6;const M:usize=10;const MAX_INPUT:usize=60;
const Graph=struct{n:usize,m:usize,s:usize,t:usize,u:[M]usize,v:[M]usize,cap:[M]i64,deg:[N]usize,rot:[N][N]usize};
fn parse(a:[*c]const i64,len:usize) ?Graph {
 if(a==null||len<4||len>MAX_INPUT)return null;const n0=a[0];const m0=a[1];const s0=a[2];const t0=a[3];if(n0<2||n0>N||m0<1||m0>M||s0<0||s0>=n0||t0<0||t0>=n0||s0==t0)return null;
 const n:usize=@intCast(n0);const m:usize=@intCast(m0);var g=Graph{.n=n,.m=m,.s=@intCast(s0),.t=@intCast(t0),.u=[_]usize{0}**M,.v=[_]usize{0}**M,.cap=[_]i64{0}**M,.deg=[_]usize{0}**N,.rot=[_][N]usize{[_]usize{0}**N}**N};if(len<4+3*m)return null;
 var pairs=[_]bool{false}**(N*N);var pos:usize=4;for(0..m)|e|{const x=a[pos];const y=a[pos+1];const c=a[pos+2];pos+=3;if(x<0||x>=n0||y<0||y>=n0||x==y||c<0||c>5)return null;const ux:usize=@intCast(x);const vy:usize=@intCast(y);const k1=ux*N+vy;const k2=vy*N+ux;if(pairs[k1]||pairs[k2])return null;pairs[k1]=true;pairs[k2]=true;g.u[e]=ux;g.v[e]=vy;g.cap[e]=c;}
 var occ=[_]u8{0}**(M*2);var seen=[_]bool{false}**(N*M);for(0..n)|x|{if(pos>=len)return null;const d0=a[pos];pos+=1;if(d0<0||d0>=n0||pos+@as(usize,@intCast(d0))>len)return null;const d:usize=@intCast(d0);g.deg[x]=d;for(0..d)|j|{const e0=a[pos];pos+=1;if(e0<0||e0>=m0)return null;const e:usize=@intCast(e0);const ix=x*M+e;if(seen[ix])return null;seen[ix]=true;g.rot[x][j]=e;if(g.u[e]==x){occ[e*2]+=1;}else if(g.v[e]==x){occ[e*2+1]+=1;}else return null;}}
 if(pos!=len)return null;for(0..m)|e|{if(occ[e*2]!=1||occ[e*2+1]!=1)return null;}
 var vis=[_]bool{false}**N;var q=[_]usize{0}**N;var head:usize=0;var tail:usize=0;vis[g.s]=true;q[tail]=g.s;tail+=1;while(head<tail){const x=q[head];head+=1;for(0..m)|e|{const y=if(g.u[e]==x)g.v[e] else if(g.v[e]==x)g.u[e] else N;if(y<N&&!vis[y]){vis[y]=true;q[tail]=y;tail+=1;}}}for(0..n)|x|{if(!vis[x])return null;}return g;
}
fn residual(g:*const Graph,flow:*const [M]i64,x:usize,e:usize)i64{return if(g.u[e]==x)g.cap[e]-flow[e] else flow[e];}
fn put(out:[*c]u8,v:i64)void{const bits:u64=@bitCast(v);for(0..8)|b|out[b]=@truncate(bits>>@intCast(8*b));}
export fn st_planar_leftmost_augmenting_flow(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 const parsed=parse(input,length) orelse return -1;var g=parsed;var flow=[_]i64{0}**M;var total:i64=0;
 while(true){var vis=[_]bool{false}**N;var par=[_]i32{-1}**N;var pe=[_]i32{-1}**N;var pd=[_]i32{0}**N;var next=[_]usize{0}**N;var stack=[_]usize{0}**N;var top:usize=0;vis[g.s]=true;stack[top]=g.s;top+=1;
  while(top>0&&!vis[g.t]){const x=stack[top-1];if(next[x]>=g.deg[x]){top-=1;continue;}const e=g.rot[x][next[x]];next[x]+=1;const y=if(g.u[e]==x)g.v[e] else g.u[e];if(residual(&g,&flow,x,e)>0&&!vis[y]){vis[y]=true;par[y]=@intCast(x);pe[y]=@intCast(e);pd[y]=if(g.u[e]==x)1 else -1;stack[top]=y;top+=1;}}
  if(!vis[g.t])break;var delta:i64=1000000;var y=g.t;while(y!=g.s){const x:usize=@intCast(par[y]);const e:usize=@intCast(pe[y]);delta=@min(delta,residual(&g,&flow,x,e));y=x;}y=g.t;while(y!=g.s){const e:usize=@intCast(pe[y]);flow[e]+=@as(i64,pd[y])*delta;y=@intCast(par[y]);}total+=delta;
 }
 if(output==null||capacity<8)return -2;put(output,total);return 8;
}
