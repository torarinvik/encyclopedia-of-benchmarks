const MAX_CELLS: usize = 400;
const INF: i32 = 1_000_000;
fn heuristic(a: usize, b: usize, cols: usize) i32 { const dy: i32 = @intCast(a / cols); const by: i32 = @intCast(b / cols); const dx: i32 = @intCast(a % cols); const bx: i32 = @intCast(b % cols); const sq = (dy-by)*(dy-by)+(dx-bx)*(dx-bx); var h: i32 = 0; while ((h+1)*(h+1) <= sq) h += 1; return h; }
fn put(out: [*]u8, slot: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |i| out[slot*8+i]=@truncate(bits >> @intCast(i*8)); }
export fn bidirectional_a_star(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
 if(input==null or length<6)return -1;const r0=input[0];const c0=input[1];if(r0<1 or r0>20 or c0<1 or c0>20)return -1;const rows:usize=@intCast(r0);const cols:usize=@intCast(c0);const cells=rows*cols;
 const sy=input[2];const sx=input[3];const gy=input[4];const gx=input[5];if(sy<0 or sy>=r0 or sx<0 or sx>=c0 or gy<0 or gy>=r0 or gx<0 or gx>=c0 or length!=6+cells)return -1;const start:usize=@intCast(sy)*cols+@as(usize,@intCast(sx));const goal:usize=@intCast(gy)*cols+@as(usize,@intCast(gx));
 var blocked:[MAX_CELLS]bool=@splat(false);for(0..cells)|i|{if(input[6+i]!=0 and input[6+i]!=1)return -1;blocked[i]=input[6+i]==1;}if(blocked[start] or blocked[goal])return -1;
 var g:[2][MAX_CELLS]i32=@splat(@splat(INF));var parent:[2][MAX_CELLS]i32=@splat(@splat(-1));var order:[2][MAX_CELLS]i32=@splat(@splat(0));var opened:[2][MAX_CELLS]bool=@splat(@splat(false));var closed:[2][MAX_CELLS]bool=@splat(@splat(false));var seq:[2]i32=@splat(0);
 g[0][start]=0;g[1][goal]=0;opened[0][start]=true;opened[1][goal]=true;seq[0]=1;seq[1]=1;const dr=[_]i32{-1,0,1,0};const dc=[_]i32{0,-1,0,1};var best=INF;var meet: i32 = -1;
 while(true){var min_g=[_]i32{INF,INF};for(0..2)|s|{for(0..cells)|v|{if(opened[s][v] and g[s][v]<min_g[s])min_g[s]=g[s][v];}}if(best<INF and (min_g[0]==INF or min_g[1]==INF or min_g[0]+min_g[1]>=best))break;
  for(0..2)|s|{const target=if(s==0)goal else start;var chosen: i32 = -1;var best_f=INF;for(0..cells)|v|{if(opened[s][v]){const f=g[s][v]+heuristic(v,target,cols);if(chosen<0 or f<best_f or (f==best_f and order[s][v]<order[s][@intCast(chosen)])){chosen=@intCast(v);best_f=f;}}}if(chosen<0)continue;const u:usize=@intCast(chosen);opened[s][u]=false;closed[s][u]=true;if(g[1-s][u]<INF and g[s][u]+g[1-s][u]<best){best=g[s][u]+g[1-s][u];meet=chosen;}const y:i32=@intCast(u/cols);const x:i32=@intCast(u%cols);
   for(0..4)|d|{const ny=y+dr[d];const nx=x+dc[d];if(ny<0 or ny>=r0 or nx<0 or nx>=c0)continue;const v:usize=@intCast(ny)*cols+@as(usize,@intCast(nx));if(blocked[v] or closed[s][v])continue;const ng=g[s][u]+1;if(ng<g[s][v]){g[s][v]=ng;parent[s][v]=chosen;opened[s][v]=true;order[s][v]=seq[s];seq[s]+=1;if(g[1-s][v]<INF and ng+g[1-s][v]<best){best=ng+g[1-s][v];meet=@intCast(v);}}}
  }
  var any=false;for(0..2)|s|{for(0..cells)|v|{any=any or opened[s][v];}}if(!any)break;
 }
 var path:[MAX_CELLS]usize=undefined;var rev:[MAX_CELLS]usize=undefined;var count:usize=0;if(meet<0){path[0]=start;count=1;}else{var n:usize=0;var v=meet;while(v>=0){rev[n]=@intCast(v);n+=1;v=parent[0][@intCast(v)];}while(n>0){n-=1;path[count]=rev[n];count+=1;}v=parent[1][@intCast(meet)];while(v>=0){path[count]=@intCast(v);count+=1;v=parent[1][@intCast(v)];}}
 const bytes=(1+2*count)*8;if(output==null or capacity<bytes)return -2;put(output,0,@intCast(count));for(0..count)|i|{put(output,1+2*i,@intCast(path[i]/cols));put(output,2+2*i,@intCast(path[i]%cols));}return @intCast(bytes);
}
