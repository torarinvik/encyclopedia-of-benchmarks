module packet_routing_work_conserving_schedule
const max_n=8
const max_m=12
const max_p=8
const max_hops=56
const max_input=99
fn put_i64(mut output &u8,word int,value i64){bits:=u64(value);for b in 0..8{unsafe{output[word*8+b]=u8((bits>>(8*b))&255)}}}
@[export:'packet_routing_work_conserving_schedule']
pub fn packet_routing_work_conserving_schedule(input &i64,length usize,mut output &u8,capacity usize)i64{
 if input==nil||length<3||length>max_input{return -1};n0:=unsafe{input[0]};m0:=unsafe{input[1]};p0:=unsafe{input[2]};if n0<2||n0>max_n||m0<1||m0>max_m||p0<1||p0>max_p{return -1};n:=int(n0);m:=int(m0);p:=int(p0);mut at:=3;if at+2*m>int(length){return -1}
 mut eu:=[max_m]int{};mut ev:=[max_m]int{};mut seen:=[max_n*max_n]bool{}
 for e in 0..m{u:=unsafe{input[at]};v:=unsafe{input[at+1]};at+=2;if u<0||u>=n0||v<0||v>=n0||u==v{return -1};lo:=int(u);hi:=int(v);if lo>hi{lo,hi=hi,lo};key:=lo*max_n+hi;if seen[key]{return -1};seen[key]=true;eu[e]=int(u);ev[e]=int(v)}
 mut plen:=[max_p]int{};mut paths:=[max_p][max_n]int{}
 for q in 0..p{if at+2>int(length){return -1};start:=unsafe{input[at]};k:=unsafe{input[at+1]};at+=2;if start<0||start>=n0||k<1||k>=n0||at+int(k)>int(length){return -1};plen[q]=int(k);mut cur:=int(start);mut usedv:=[max_n]bool{};mut usede:=[max_m]bool{};usedv[cur]=true
  for j in 0..plen[q]{e0:=unsafe{input[at]};at++;if e0<0||e0>=m0{return -1};e:=int(e0);if usede[e]{return -1};usede[e]=true;paths[q][j]=e;if eu[e]==cur{cur=ev[e]}else if ev[e]==cur{cur=eu[e]}else{return -1};if usedv[cur]{return -1};usedv[cur]=true}}
 if at!=int(length){return -1};mut pos:=[max_p]int{};mut tt:=[max_hops]i64{};mut te:=[max_hops]i64{};mut tp:=[max_hops]i64{};mut count:=0;mut time:=0
 for{mut active:=false;mut chosen:=[max_m]int{};for e in 0..m{chosen[e]=-1};for q in 0..p{if pos[q]<plen[q]{active=true;e:=paths[q][pos[q]];if chosen[e]<0{chosen[e]=q}}};if !active{break};for e in 0..m{if chosen[e]>=0{if count>=max_hops{return -1};tt[count]=i64(time);te[count]=i64(e);tp[count]=i64(chosen[e]);count++;pos[chosen[e]]++}};time++;if time>max_n*max_p{return -1}}
 words:=2+3*count;bytes:=words*8;if output==nil||capacity<usize(bytes){return -2};put_i64(mut output,0,i64(time));put_i64(mut output,1,i64(count));for i in 0..count{put_i64(mut output,2+3*i,tt[i]);put_i64(mut output,3+3*i,te[i]);put_i64(mut output,4+3*i,tp[i])};return i64(bytes)
}
