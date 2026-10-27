const std=@import("std");
const N:usize=8;const M:usize=16;const K:usize=8;const MAX_INPUT:usize=75;const MAX_OUTPUT:usize=648;
fn put(out:[*c]u8,at:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|i|out[at+i]=@truncate(b>>(8*@as(u6,@intCast(i))));}
export fn truthful_ufp_greedy1(values:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(values==null or length<9 or length>MAX_INPUT)return -1;if(values[0]<2 or values[0]>N or values[1]<1 or values[1]>M or values[2]<1 or values[2]>K)return -1;
 const nv:usize=@intCast(values[0]);const m:usize=@intCast(values[1]);const k:usize=@intCast(values[2]);if(length!=3+3*m+3*k)return -1;
 var eu:[M]usize=@splat(0);var ev:[M]usize=@splat(0);var caps:[M]usize=@splat(0);var prices:[M]f64=@splat(0.0);var minimum:usize=9;var pu:i64=-1;var pv:i64=-1;
 for(0..m)|e|{const u=values[3+3*e];const v=values[4+3*e];const b=values[5+3*e];if(u<0 or v<=u or v>=@as(i64,@intCast(nv)) or b<2 or b>8 or (e>0 and (u<pu or (u==pu and v<=pv))))return -1;eu[e]=@intCast(u);ev[e]=@intCast(v);caps[e]=@intCast(b);prices[e]=1.0/@as(f64,@floatFromInt(b));minimum=@min(minimum,caps[e]);pu=u;pv=v;}
 var src:[K]usize=@splat(0);var dst:[K]usize=@splat(0);var bids:[K]i64=@splat(0);for(0..k)|i|{const s=values[3+3*m+3*i];const t=values[4+3*m+3*i];const c=values[5+3*m+3*i];if(s<0 or s>=@as(i64,@intCast(nv)) or t<0 or t>=@as(i64,@intCast(nv)) or s==t or c<1 or c>100)return -1;src[i]=@intCast(s);dst[i]=@intCast(t);bids[i]=c;}
 const threshold=std.math.pow(f64,2.718281828459045,@as(f64,@floatFromInt(minimum-1)))*@as(f64,@floatFromInt(m));var live:[K]bool=@splat(false);for(0..k)|i|live[i]=true;var selected:[K]usize=@splat(0);var path_len:[K]usize=@splat(0);var paths:[K*N]usize=@splat(0);var count:usize=0;
 while(count<k){var best:?usize=null;var best_score:f64=-1.0;var route_table:[K*N]usize=@splat(0);var route_len:[K]usize=@splat(0);
  for(0..k)|i|{if(live[i]){var dist:[N]f64=@splat(1e300);var parent:[N]i64=@splat(-1);var used:[N]bool=@splat(false);dist[src[i]]=0.0;
   for(0..nv)|_|{var u:?usize=null;for(0..nv)|v|{if(!used[v] and (u==null or dist[v]<dist[u.?] or (dist[v]==dist[u.?] and v<u.?)))u=v;}if(u==null or dist[u.?]>=1e299)break;const at=u.?;used[at]=true;
    for(0..m)|e|{var v:?usize=null;if(eu[e]==at){v=ev[e];}else if(ev[e]==at){v=eu[e];}if(v!=null and !used[v.?]){const cand=dist[at]+prices[e];if(cand<dist[v.?] or (cand==dist[v.?] and (parent[v.?]<0 or @as(i64,@intCast(at))<parent[v.?]))){dist[v.?]=cand;parent[v.?]=@intCast(at);}}}
   }
   if(dist[dst[i]]>=1e299)return -1;var rev:[N]usize=@splat(0);var len:usize=0;var v=dst[i];while(v!=src[i] and len<nv){rev[len]=v;len+=1;if(parent[v]<0)return -1;v=@intCast(parent[v]);}if(v!=src[i] or len>=nv)return -1;rev[len]=src[i];len+=1;route_len[i]=len;for(0..len)|q|route_table[i*N+q]=rev[len-1-q];const score=@as(f64,@floatFromInt(bids[i]))/dist[dst[i]];if(best==null or score>best_score){best=i;best_score=score;}
  }}
  if(best==null)break;const winner=best.?;live[winner]=false;selected[count]=winner;path_len[count]=route_len[winner];for(0..path_len[count])|q|paths[count*N+q]=route_table[winner*N+q];count+=1;
  for(0..path_len[count-1]-1)|q|{const u=paths[(count-1)*N+q];const v=paths[(count-1)*N+q+1];for(0..m)|e|{if((eu[e]==u and ev[e]==v) or (eu[e]==v and ev[e]==u))prices[e]*=std.math.pow(f64,threshold,1.0/@as(f64,@floatFromInt(caps[e]-1)));}}
  var dual:f64=0;for(0..m)|e|dual+=@as(f64,@floatFromInt(caps[e]))*prices[e];if(dual>=threshold)break;
 }
 var words:usize=1;for(0..count)|i|words+=2+path_len[i];const bytes=8*words;if(output==null or capacity<bytes)return -2;var staged:[MAX_OUTPUT]u8=@splat(0);put(&staged,0,@intCast(count));var w:usize=1;for(0..count)|i|{put(&staged,8*w,@intCast(selected[i]));w+=1;put(&staged,8*w,@intCast(path_len[i]));w+=1;for(0..path_len[i])|q|{put(&staged,8*w,@intCast(paths[i*N+q]));w+=1;}}for(0..bytes)|i|output[i]=staged[i];return @intCast(bytes);
}
