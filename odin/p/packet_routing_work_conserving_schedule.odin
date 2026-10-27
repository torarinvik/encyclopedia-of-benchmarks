package packet_routing_work_conserving_schedule
import "core:c"
N::8;M::12;P::8;HOPS::56;MAX_INPUT::99
put_i64::proc "contextless"(out:[^]u8,word:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[word*8+b]=u8((bits>>(8*b))&255)}}
@(export)
packet_routing_work_conserving_schedule::proc "c"(input:[^]i64,input_length:c.size_t,output:[^]u8,output_capacity:c.size_t)->i64{
 if input==nil||input_length<3||input_length>MAX_INPUT do return -1
 n0,m0,p0:=input[0],input[1],input[2];if n0<2||n0>N||m0<1||m0>M||p0<1||p0>P do return -1
 n,m,p:=int(n0),int(m0),int(p0);at:=3;if at+2*m>int(input_length) do return -1
 eu,ev:[M]int={};seen:[N][N]bool={}
 for e:=0;e<m;e+=1{u,v:=input[at],input[at+1];at+=2;if u<0||u>=n0||v<0||v>=n0||u==v do return -1;lo,hi:=int(u),int(v);if lo>hi{lo,hi=hi,lo};if seen[lo][hi] do return -1;seen[lo][hi]=true;eu[e],ev[e]=int(u),int(v)}
 plen:[P]int={};paths:[P][N]int={}
 for q:=0;q<p;q+=1{if at+2>int(input_length) do return -1;start,k:=input[at],input[at+1];at+=2;if start<0||start>=n0||k<1||k>=n0||at+int(k)>int(input_length) do return -1;plen[q]=int(k);cur:=int(start);usedv:[N]bool={};usede:[M]bool={};usedv[cur]=true
  for j:=0;j<plen[q];j+=1{e0:=input[at];at+=1;if e0<0||e0>=m0 do return -1;e:=int(e0);if usede[e] do return -1;usede[e]=true;paths[q][j]=e;if eu[e]==cur{cur=ev[e]}else if ev[e]==cur{cur=eu[e]}else{return -1};if usedv[cur] do return -1;usedv[cur]=true}}
 if at!=int(input_length) do return -1
 pos:[P]int={};tt,te,tp:[HOPS]i64={};count,time:=0,0
 for{active:=false;chosen:[M]int={};for e:=0;e<m;e+=1{chosen[e]=-1};for q:=0;q<p;q+=1{if pos[q]<plen[q]{active=true;e:=paths[q][pos[q]];if chosen[e]<0{chosen[e]=q}}};if !active{break};for e:=0;e<m;e+=1{if chosen[e]>=0{if count>=HOPS do return -1;tt[count],te[count],tp[count]=i64(time),i64(e),i64(chosen[e]);count+=1;pos[chosen[e]]+=1}};time+=1;if time>N*P do return -1}
 words:=2+3*count;bytes:=words*8;if output==nil||output_capacity<c.size_t(bytes) do return -2;put_i64(output,0,i64(time));put_i64(output,1,i64(count));for i:=0;i<count;i+=1{put_i64(output,2+3*i,tt[i]);put_i64(output,3+3*i,te[i]);put_i64(output,4+3*i,tp[i])};return i64(bytes)
}
