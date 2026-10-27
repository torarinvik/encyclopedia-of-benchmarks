module color_coding_random_k_path
const max_n=12
const max_m=66
const max_k=6
const max_trials=8
const max_input=232
const max_output=64
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[offset+byte]=u8((bits>>(8*byte))&255)}}}
fn path_less(a []int,b []int,length int)bool{for i in 0..length{if a[i]!=b[i]{return a[i]<b[i]}};false}
@[export:'color_coding_random_k_path']
pub fn color_coding_random_k_path(input &i64,length usize,mut output &u8,capacity usize)i64{
 if input==nil||length<4||length>max_input{return -1};n64:=unsafe{input[0]};m64:=unsafe{input[1]};k64:=unsafe{input[2]};t64:=unsafe{input[3]}
 if n64<1||n64>max_n||m64<0||m64>max_m||k64<1||k64>max_k||k64>n64||t64<1||t64>max_trials{return -1}
 n:=int(n64);m:=int(m64);k:=int(k64);trials:=int(t64);edge_start:=4;color_start:=edge_start+2*m;if length!=usize(color_start+trials*n){return -1}
 mut adj:=[max_n]u16{}
 for e in 0..m{a64:=unsafe{input[edge_start+2*e]};b64:=unsafe{input[edge_start+2*e+1]};if a64<0||b64<0||a64>=n64||b64>=n64||a64==b64{return -1};a:=int(a64);b:=int(b64);if adj[a]&(u16(1)<<b)!=0{return -1};adj[a]|=u16(1)<<b;adj[b]|=u16(1)<<a}
 for trial in 0..trials{for v in 0..n{color:=unsafe{input[color_start+trial*n+v]};if color<0||color>=k64{return -1}}}
 full:=(1<<k)-1
 for trial in 0..trials{
  mut colors:=[max_n]int{};for v in 0..n{colors[v]=int(unsafe{input[color_start+trial*n+v]})}
  mut reachable:=[1<<max_k][max_n]bool{};mut paths:=[1<<max_k][max_n][max_k]int{}
  for mask in 0..(full+1){for v in 0..n{for j in 0..k{paths[mask][v][j]=-1}}}
  for v in 0..n{mask:=1<<colors[v];reachable[mask][v]=true;paths[mask][v][0]=v}
  for mask in 1..(full+1){mut path_len:=0;mut bits:=mask;for bits!=0{bits&=bits-1;path_len++};for v in 0..n{if reachable[mask][v]&&mask!=full{for u in 0..n{bit:=1<<colors[u];if adj[v]&(u16(1)<<u)==0||mask&bit!=0{continue};next:=mask|bit;mut candidate:=[max_k]int{};for j in 0..path_len{candidate[j]=paths[mask][v][j]};candidate[path_len]=u;if !reachable[next][u]||path_less(candidate[..],paths[next][u][..],path_len+1){reachable[next][u]=true;for j in 0..(path_len+1){paths[next][u][j]=candidate[j]}}}}}}
  mut best:=-1;for v in 0..n{if reachable[full][v]&&(best<0||path_less(paths[full][v][..],paths[full][best][..],k)){best=v}}
  if best>=0{bytes:=8*(k+2);if output==nil||capacity<usize(bytes){return -2};mut staged:=[max_output]u8{};put_i64(mut &staged[0],0,1);put_i64(mut &staged[0],8,i64(trial+1));for j in 0..k{put_i64(mut &staged[0],8*(j+2),i64(paths[full][best][j]))};for i in 0..bytes{unsafe{output[i]=staged[i]}};return i64(bytes)}
 }
 if output==nil||capacity<16{return -2};mut staged:=[16]u8{};put_i64(mut &staged[0],0,0);put_i64(mut &staged[0],8,0);for i in 0..16{unsafe{output[i]=staged[i]}};i64(16)
}
