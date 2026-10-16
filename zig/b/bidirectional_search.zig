const N:usize=64;const MAX_ARCS:usize=N*(N-1);
fn put(out:[*]u8,slot:usize,v:i64)void{const b:u64=@bitCast(v);for(0..8)|i|out[slot*8+i]=@truncate(b>>@intCast(i*8));}
export fn bidirectional_search(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<4)return -1;const nn=input[0];if(nn<1 or nn>N)return -1;const n:usize=@intCast(nn);const start0=input[1];const goal0=input[2];const mm=input[3];if(start0<0 or start0>=nn or goal0<0 or goal0>=nn or mm<0 or mm>MAX_ARCS or length!=4+2*@as(usize,@intCast(mm)))return -1;const m:usize=@intCast(mm);
 var adj:[N][N-1]usize=@splat(@splat(0));var deg:[N]usize=@splat(0);var edge:[N][N]bool=@splat(@splat(false));for(0..m)|i|{const u0=input[4+2*i];const v0=input[5+2*i];if(u0<0 or u0>=nn or v0<0 or v0>=nn or u0==v0)return -1;const u:usize=@intCast(u0);const v:usize=@intCast(v0);if(edge[u][v])return -1;edge[u][v]=true;adj[u][deg[u]]=v;deg[u]+=1;}for(0..n)|u|{for(0..n)|v|{if(edge[u][v]!=edge[v][u])return -1;}}
 var path:[N]usize=@splat(0);var pc:usize=0;const start:usize=@intCast(start0);const goal:usize=@intCast(goal0);if(start==goal){path[pc]=start;pc+=1;}else{var parent:[2][N]i32=@splat(@splat(-2));var q:[2][N]usize=@splat(@splat(0));var head:[2]usize=@splat(0);var tail:[2]usize=@splat(0);parent[0][start]= -1;parent[1][goal]= -1;q[0][0]=start;q[1][0]=goal;tail[0]=1;tail[1]=1;var meet:i32= -1;
  while(head[0]<tail[0] and head[1]<tail[1] and meet<0){for(0..2)|s|{if(meet>=0)break;const cur=q[s][head[s]];head[s]+=1;for(0..deg[cur])|j|{const v=adj[cur][j];if(parent[s][v]!= -2)continue;parent[s][v]=@intCast(cur);q[s][tail[s]]=v;tail[s]+=1;if(parent[1-s][v]!= -2){meet=@intCast(v);break;}}}}
  if(meet>=0){const mnode:usize=@intCast(meet);var rev:[N]usize=@splat(0);var k:usize=0;var v:i32=meet;while(v!= -1){rev[k]=@intCast(v);k+=1;v=parent[0][@intCast(v)];}while(k>0){k-=1;path[pc]=rev[k];pc+=1;}v=parent[1][mnode];while(v!= -1){path[pc]=@intCast(v);pc+=1;v=parent[1][@intCast(v)];}}
 }
 const bytes=(1+pc)*8;if(output==null or capacity<bytes)return -2;put(output,0,@intCast(pc));for(0..pc)|i|put(output,1+i,@intCast(path[i]));return @intCast(bytes);
}
