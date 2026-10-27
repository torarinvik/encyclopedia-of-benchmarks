module two_edge_connected_spanning_subgraph_greedy
import core.c
const max_n=8
const max_m=28
const max_input=59
fn put(o &u8,at int,x i64){b:=u64(x);for i in 0..8{o[at+i]=u8((b>>(8*i))&255)}}
fn connected(n,m int,u,v []int,on []bool,skip int)bool{mut seen:=[]bool{len:max_n,init:false};mut q:=[]int{len:max_n,init:0};mut head:=0;mut tail:=1;q[0]=0;seen[0]=true;for head<tail{a:=q[head];head++;for e in 0..m{if !on[e]||e==skip{continue};mut b:=max_n;if u[e]==a{b=v[e]}else if v[e]==a{b=u[e]};if b<max_n&&!seen[b]{seen[b]=true;q[tail]=b;tail++}}};for i in 0..n{if !seen[i]{return false}};return true}
fn edge_connected(n,m int,u,v []int,on []bool)bool{if !connected(n,m,u,v,on,-1){return false};for e in 0..m{if on[e]&&!connected(n,m,u,v,on,e){return false}};return true}
@[export: 'two_edge_connected_spanning_subgraph_greedy']
pub fn two_edge_connected_spanning_subgraph_greedy(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<2||length>max_input{return -1};n0,m0:=input[0],input[1];if n0<3||n0>8||m0<3||m0>28||length!=usize(2+2*m0){return -1};n,m:=int(n0),int(m0)
  mut u:=[]int{len:max_m,init:0};mut v:=[]int{len:max_m,init:0};mut on:=[]bool{len:max_m,init:false}
  for i in 0..m{a,b:=input[2+2*i],input[3+2*i];if a<0||a>=b||b>=n0{return -1};u[i]=int(a);v[i]=int(b);on[i]=true;for j in 0..i{if u[i]==u[j]&&v[i]==v[j]{return -1}}}
  if !edge_connected(n,m,u,v,on){return -1};for e in 0..m{on[e]=false;if !edge_connected(n,m,u,v,on){on[e]=true}}
  mut count:=0;for e in 0..m{if on[e]{count++}};bytes:=8*(1+2*count);if output==nil||capacity<usize(bytes){return -2};put(output,0,i64(count));mut at:=8
  for a in 0..n{for b in a+1..n{for e in 0..m{if on[e]&&u[e]==a&&v[e]==b{put(output,at,i64(a));put(output,at+8,i64(b));at+=16}}}}
  return i64(bytes)
 }
}
