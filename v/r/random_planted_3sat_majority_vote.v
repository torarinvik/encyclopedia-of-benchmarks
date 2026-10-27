module random_planted_3sat_majority_vote
const max_vars=12
const max_clauses=32
const max_input=98
const max_output=96
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[offset+byte]=u8((bits>>(8*byte))&255)}}}
@[export:'random_planted_3sat_majority_vote']
pub fn random_planted_3sat_majority_vote(input &i64,length usize,mut output &u8,capacity usize)i64{
 if input==nil||length<2||length>max_input{return -1};n64:=unsafe{input[0]};m64:=unsafe{input[1]};if n64<3||n64>max_vars||m64<0||m64>max_clauses{return -1};n:=int(n64);m:=int(m64);if length!=usize(2+3*m){return -1}
 mut positive:=[max_vars]int{};mut negative:=[max_vars]int{}
 for c in 0..m{mut seen:=[max_vars]bool{};for j in 0..3{lit:=unsafe{input[2+3*c+j]};if lit==0||lit < -n64||lit>n64{return -1};v:=int(if lit>0{lit}else{-lit})-1;if seen[v]{return -1};seen[v]=true;if lit>0{positive[v]++}else{negative[v]++}}}
 bytes:=8*n;if output==nil||capacity<usize(bytes){return -2};mut staged:=[max_output]u8{};for v in 0..n{put_i64(mut &staged[0],8*v,if positive[v]>negative[v]{1}else{-1})};for i in 0..bytes{unsafe{output[i]=staged[i]}};i64(bytes)
}
