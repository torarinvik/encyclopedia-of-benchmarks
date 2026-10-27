module p2p_chord_finger_lookup
const max_nodes=16
const max_bits=6
const max_input=116
const max_output=128
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[offset+byte]=u8((bits>>(8*byte))&255)}}}
@[export:'p2p_chord_finger_lookup']
pub fn p2p_chord_finger_lookup(input &i64,length usize,mut output &u8,capacity usize)i64{
 if input==nil||length<4||length>max_input{return -1}
 bits64:=unsafe{input[0]};n64:=unsafe{input[1]};if bits64<1||bits64>max_bits||n64<2||n64>max_nodes{return -1}
 bits:=int(bits64);n:=int(n64);ring:=1<<bits
 start64:=unsafe{input[2]};key:=unsafe{input[3]};if n>ring||start64<0||start64>=n64||key<0||key>=i64(ring){return -1}
 if length!=usize(4+n+n*bits){return -1}
 mut ids:=[max_nodes]int{};mut fingers:=[max_nodes*max_bits]int{}
 for i in 0..n{raw:=unsafe{input[4+i]};if raw<0||raw>=i64(ring)||(i>0&&raw<=i64(ids[i-1])){return -1};ids[i]=int(raw)}
 for node in 0..n{for level in 0..bits{target:=(ids[node]+(1<<level))%ring;mut successor:=0;for successor<n&&ids[successor]<target{successor++};if successor==n{successor=0};raw:=unsafe{input[4+n+node*bits+level]};if raw<0||raw>=n64||int(raw)!=successor{return -1};fingers[node*bits+level]=successor}}
 mut owner:=0;for owner<n&&ids[owner]<int(key){owner++};if owner==n{owner=0}
 mut route:=[max_nodes]int{};mut route_len:=1;mut current:=int(start64);route[0]=current
 for _ in 0..n{if current==owner{break};target_distance:=(ids[owner]-ids[current]+ring)%ring;mut chosen:=-1;for level in 0..bits{lev:=bits-1-level;candidate:=fingers[current*bits+lev];progress:=(ids[candidate]-ids[current]+ring)%ring;if progress>0&&progress<=target_distance{chosen=candidate;break}};if chosen<0||route_len>=n{return -1};for j in 0..route_len{if route[j]==chosen{return -1}};current=chosen;route[route_len]=current;route_len++}
 if current!=owner{return -1};bytes:=8*route_len;if output==nil||capacity<usize(bytes){return -2};mut staged:=[max_output]u8{};for i in 0..route_len{put_i64(mut &staged[0],8*i,i64(ids[route[i]]))};for i in 0..bytes{unsafe{output[i]=staged[i]}};i64(bytes)
}
