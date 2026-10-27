package truthful_ufp_greedy1

import "core:c"
import "core:math"

MAX_N :: 8
MAX_M :: 16
MAX_K :: 8
MAX_INPUT :: 75
MAX_OUTPUT :: 648
put_i64 :: proc(out:[^]u8,offset:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[offset+b]=u8((bits>>(8*b))&255)}}

@(export)
truthful_ufp_greedy1 :: proc "c" (values:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if values==nil||int(length)<9||int(length)>MAX_INPUT do return -1
 if values[0]<2||values[0]>i64(MAX_N)||values[1]<1||values[1]>i64(MAX_M)||values[2]<1||values[2]>i64(MAX_K) do return -1
 nv,m,k:=int(values[0]),int(values[1]),int(values[2]);if int(length)!=3+3*m+3*k do return -1
 eu:[MAX_M]int;ev:[MAX_M]int;caps:[MAX_M]int;prices:[MAX_M]f64;minimum:=9;pu:=-1;pv:=-1
 for e:=0;e<m;e+=1{u,v,b:=values[3+3*e],values[4+3*e],values[5+3*e];if u<0||v<=u||v>=i64(nv)||b<2||b>8||(e>0&&(u<pu||(u==pu&&v<=pv)))do return -1;eu[e]=int(u);ev[e]=int(v);caps[e]=int(b);prices[e]=1.0/f64(b);if caps[e]<minimum do minimum=caps[e];pu=u;pv=v}
 src:[MAX_K]int;dst:[MAX_K]int;bid:[MAX_K]int
 for i:=0;i<k;i+=1{s,t,c:=values[3+3*m+3*i],values[4+3*m+3*i],values[5+3*m+3*i];if s<0||s>=i64(nv)||t<0||t>=i64(nv)||s==t||c<1||c>100 do return -1;src[i]=int(s);dst[i]=int(t);bid[i]=int(c)}
 threshold:=math.pow_f64(2.718281828459045,f64(minimum-1))*f64(m);live:[MAX_K]bool = {};for i:=0;i<k;i+=1{live[i]=true};chosen:[MAX_K]int;path_len:[MAX_K]int;paths:[MAX_K*MAX_N]int;count:=0
 for count<k{
  best:=-1;best_score:=-1.0;route_table:[MAX_K*MAX_N]int;route_len:[MAX_K]int
  for i:=0;i<k;i+=1{if live[i]{dist:[MAX_N]f64;parent:[MAX_N]int;used:[MAX_N]bool = {};for v:=0;v<nv;v+=1{dist[v]=1e300;parent[v]=-1};dist[src[i]]=0
   for step:=0;step<nv;step+=1{u:=-1;for v:=0;v<nv;v+=1{if !used[v]&&(u<0||dist[v]<dist[u]||(dist[v]==dist[u]&&v<u)){u=v}};if u<0||dist[u]>=1e299 do break;used[u]=true
    for e:=0;e<m;e+=1{v:=-1;if eu[e]==u{v=ev[e]}else if ev[e]==u{v=eu[e]};if v>=0&&!used[v]{candidate:=dist[u]+prices[e];if candidate<dist[v]||(candidate==dist[v]&&(parent[v]<0||u<parent[v])){dist[v]=candidate;parent[v]=u}}}
   }
   if dist[dst[i]]>=1e299 do return -1;reverse:[MAX_N]int;length_path:=0;v:=dst[i];for v!=src[i]&&length_path<nv{reverse[length_path]=v;length_path+=1;if parent[v]<0 do return -1;v=parent[v]};if v!=src[i]||length_path>=nv do return -1;reverse[length_path]=src[i];length_path+=1;route_len[i]=length_path
   for q:=0;q<length_path;q+=1{route_table[i*MAX_N+q]=reverse[length_path-1-q]};score:=f64(bid[i])/dist[dst[i]];if best<0||score>best_score{best=i;best_score=score}
  }}
  if best<0 do break;live[best]=false;chosen[count]=best;path_len[count]=route_len[best];for q:=0;q<path_len[count];q+=1{paths[count*MAX_N+q]=route_table[best*MAX_N+q]};count+=1
  for q:=0;q<path_len[count-1]-1;q+=1{u,v:=paths[(count-1)*MAX_N+q],paths[(count-1)*MAX_N+q+1];for e:=0;e<m;e+=1{if(eu[e]==u&&ev[e]==v)||(eu[e]==v&&ev[e]==u){prices[e]*=math.pow_f64(threshold,1.0/f64(caps[e]-1))}}}
  dual:=0.0;for e:=0;e<m;e+=1{dual+=f64(caps[e])*prices[e]};if dual>=threshold do break
 }
 words:=1;for i:=0;i<count;i+=1{words+=2+path_len[i]};bytes:=8*words;if output==nil||int(capacity)<bytes do return -2
 staged:[MAX_OUTPUT]u8;put_i64(&staged[0],0,i64(count));w:=1;for i:=0;i<count;i+=1{put_i64(&staged[0],8*w,i64(chosen[i]));w+=1;put_i64(&staged[0],8*w,i64(path_len[i]));w+=1;for q:=0;q<path_len[i];q+=1{put_i64(&staged[0],8*w,i64(paths[i*MAX_N+q]));w+=1}};for i:=0;i<bytes;i+=1{output[i]=staged[i]};return i64(bytes)
}
