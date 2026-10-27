module random_planted_3sat_k_opt
const max_vars=12
const max_clauses=32
const max_input=98
const max_output=104
fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[offset+byte]=u8((bits>>(8*byte))&255)}}}
fn sat_set(clauses []int,m int,n int,code u32)u32{mut set:=u32(0);for c in 0..m{mut satisfied:=false;for j in 0..3{lit:=clauses[3*c+j];v:=if lit>0{lit-1}else{-lit-1};truth:=((code>>u32(n-1-v))&1)!=0;if truth==(lit>0){satisfied=true}};if satisfied{set|=u32(1)<<u32(c)}};set}
@[export:'random_planted_3sat_k_opt']
pub fn random_planted_3sat_k_opt(input &i64,length usize,mut output &u8,capacity usize)i64{
 if input==nil||length<2||length>max_input{return -1};n64:=unsafe{input[0]};m64:=unsafe{input[1]};if n64<3||n64>max_vars||m64<0||m64>max_clauses{return -1};n:=int(n64);m:=int(m64);if length!=usize(2+3*m){return -1}
 mut clauses:=[max_clauses*3]int{};mut positive:=[max_vars]int{};mut negative:=[max_vars]int{}
 for c in 0..m{mut seen:=[max_vars]bool{};for j in 0..3{raw:=unsafe{input[2+3*c+j]};if raw==0||raw < -n64||raw>n64{return -1};lit:=int(raw);v:=if lit>0{lit-1}else{-lit-1};if seen[v]{return -1};seen[v]=true;clauses[3*c+j]=lit;if lit>0{positive[v]++}else{negative[v]++}}}
 mut current:=u32(0);for v in 0..n{if positive[v]>negative[v]{current|=u32(1)<<u32(n-1-v)}};mut full:=u32(0);if m==32{full=0xffff_ffff}else if m>0{full=(u32(1)<<u32(m))-1};mut k:=1;mut status:=i64(0)
 for{before:=sat_set(clauses[..],m,n,current);if before==full{status=1;break};mut found:=false;limit:=u32(1)<<u32(n);for candidate in u32(0)..limit{mut diff:=current^candidate;mut distance:=0;for diff!=0{diff&=diff-1;distance++};if distance==0||distance>k{continue};after:=sat_set(clauses[..],m,n,candidate);if after!=before&&(after&before)==before{current=candidate;found=true;break}};if found{continue};if k==n{status=0;break};k++}
 bytes:=8*(n+1);if output==nil||capacity<usize(bytes){return -2};mut staged:=[max_output]u8{};put_i64(mut &staged[0],0,status);for v in 0..n{put_i64(mut &staged[0],8*(v+1),if ((current>>u32(n-1-v))&1)!=0{i64(1)}else{i64(-1)})};for i in 0..bytes{unsafe{output[i]=staged[i]}};i64(bytes)
}
