module main
import math

const max_n=8
const max_m=16
const max_k=8
const max_input=75
const max_output=648
fn ufp_put(mut output &u8, offset int, value i64){bits:=u64(value);unsafe{for b in 0..8{output[offset+b]=u8((bits>>(8*b))&255)}}}

@[export: 'truthful_ufp_greedy1']
pub fn truthful_ufp_greedy1(values &i64,length usize,mut output &u8,capacity usize)i64{
 unsafe{
  if values==nil||length<9||length>max_input{return -1}
  if values[0]<2||values[0]>max_n||values[1]<1||values[1]>max_m||values[2]<1||values[2]>max_k{return -1}
  nv,m,k:=int(values[0]),int(values[1]),int(values[2]);if length!=usize(3+3*m+3*k){return -1}
  mut eu:=[max_m]int{};mut ev:=[max_m]int{};mut caps:=[max_m]int{};mut prices:=[max_m]f64{};mut minimum:=9;mut pu:=i64(-1);mut pv:=i64(-1)
  for e in 0..m{u,v,b:=values[3+3*e],values[4+3*e],values[5+3*e];if u<0||v<=u||v>=i64(nv)||b<2||b>8||(e>0&&(u<pu||(u==pu&&v<=pv))){return -1};eu[e]=int(u);ev[e]=int(v);caps[e]=int(b);prices[e]=1.0/f64(b);if caps[e]<minimum{minimum=caps[e]};pu=u;pv=v}
  mut src:=[max_k]int{};mut dst:=[max_k]int{};mut bids:=[max_k]int{}
  for i in 0..k{s,t,c:=values[3+3*m+3*i],values[4+3*m+3*i],values[5+3*m+3*i];if s<0||s>=i64(nv)||t<0||t>=i64(nv)||s==t||c<1||c>100{return -1};src[i]=int(s);dst[i]=int(t);bids[i]=int(c)}
  threshold:=math.pow(2.718281828459045,f64(minimum-1))*f64(m);mut live:=[max_k]bool{};for i in 0..k{live[i]=true};mut selected:=[max_k]int{};mut path_len:=[max_k]int{};mut paths:=[max_k*max_n]int{};mut count:=0
  for count<k{mut best:=-1;mut best_score:=-1.0;mut route_table:=[max_k*max_n]int{};mut route_len:=[max_k]int{}
   for i in 0..k{if live[i]{mut dist:=[max_n]f64{};mut parent:=[max_n]int{};mut used:=[max_n]bool{};for v in 0..nv{dist[v]=1e300;parent[v]=-1};dist[src[i]]=0.0
    for _ in 0..nv{mut u:=-1;for v in 0..nv{if !used[v]&&(u<0||dist[v]<dist[u]||(dist[v]==dist[u]&&v<u)){u=v}};if u<0||dist[u]>=1e299{break};used[u]=true
     for e in 0..m{mut v:=-1;if eu[e]==u{v=ev[e]}else if ev[e]==u{v=eu[e]};if v>=0&&!used[v]{candidate:=dist[u]+prices[e];if candidate<dist[v]||(candidate==dist[v]&&(parent[v]<0||u<parent[v])){dist[v]=candidate;parent[v]=u}}}
    }
    if dist[dst[i]]>=1e299{return -1};mut reverse:=[max_n]int{};mut plen:=0;mut v:=dst[i];for v!=src[i]&&plen<nv{reverse[plen]=v;plen++;if parent[v]<0{return -1};v=parent[v]};if v!=src[i]||plen>=nv{return -1};reverse[plen]=src[i];plen++;route_len[i]=plen;for q in 0..plen{route_table[i*max_n+q]=reverse[plen-1-q]};score:=f64(bids[i])/dist[dst[i]];if best<0||score>best_score{best=i;best_score=score}
   }}
   if best<0{break};live[best]=false;selected[count]=best;path_len[count]=route_len[best];for q in 0..path_len[count]{paths[count*max_n+q]=route_table[best*max_n+q]};count++
   for q in 0..path_len[count-1]-1{u,v:=paths[(count-1)*max_n+q],paths[(count-1)*max_n+q+1];for e in 0..m{if(eu[e]==u&&ev[e]==v)||(eu[e]==v&&ev[e]==u){prices[e]*=math.pow(threshold,1.0/f64(caps[e]-1))}}}
   mut dual:=0.0;for e in 0..m{dual+=f64(caps[e])*prices[e]};if dual>=threshold{break}
  }
  mut words:=1;for i in 0..count{words+=2+path_len[i]};bytes:=8*words;if output==nil||capacity<usize(bytes){return -2};mut staged:=[max_output]u8{};ufp_put(mut staged[0],0,i64(count));mut w:=1
  for i in 0..count{ufp_put(mut staged[0],8*w,i64(selected[i]));w++;ufp_put(mut staged[0],8*w,i64(path_len[i]));w++;for q in 0..path_len[i]{ufp_put(mut staged[0],8*w,i64(paths[i*max_n+q]));w++}}
  for i in 0..bytes{output[i]=staged[i]};return i64(bytes)
 }
}
