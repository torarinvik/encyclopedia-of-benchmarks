module graph_lua_directed_weighted
fn put_i64_le(mut output &u8,index int,value i64){mut bits:=u64(value);for b in 0..8{unsafe{output[index*8+b]=u8(bits&255)};bits>>=8}}
@[export:'graph_lua_directed_weighted']
pub fn graph_lua_directed_weighted(input &i64,length usize,mut output &u8,capacity usize)i64{
 if unsafe{input==nil}||length<2{return -1};nv:=input[0];ov:=input[1];if nv<1||nv>16||ov<0||ov>63||length!=usize(2+4*ov){return -1};n:=int(nv);ops:=int(ov)
 unsafe{mut kind:=[256]i64{};mut weight:=[256]i64{};mut result_kind:=[63]i64{};mut result_value:=[63]i64{}
 for i in 0..ops{op:=input[2+4*i];a:=input[3+4*i];b:=input[4+4*i];v:=input[5+4*i];if op<0||op>5||a<0||a>=nv||b<0||b>=nv{return -1};p:=int(a*16+b);if op==0{if v< -1000||v>1000{return -1};kind[p]=2;weight[p]=v;result_kind[i]=-1}else if op==1{if v!=0{return -1};kind[p]=1;weight[p]=0;result_kind[i]=-1}else if op==2{if v!=0{return -1};kind[p]=0;weight[p]=0;result_kind[i]=-1}else if op==3{if v!=0||kind[p]!=0{return -1};kind[p]=1;weight[p]=0;result_kind[i]=-1}else if op==4{if v!=0{return -1};result_kind[i]=kind[p];if kind[p]==2{result_value[i]=weight[p]}}else{if v!=0{return -1};if kind[p]!=0{result_kind[i]=1}else{result_kind[i]=0}}}
 mut edges:=0;for a in 0..n{for b in 0..n{if kind[a*16+b]!=0{edges++}}};words:=2+2*ops+4*edges;if output==nil||capacity<words*8{return -2};mut k:=0;put_i64_le(mut output,k,i64(ops));k++;for i in 0..ops{put_i64_le(mut output,k,result_kind[i]);k++;put_i64_le(mut output,k,result_value[i]);k++};put_i64_le(mut output,k,i64(edges));k++;for a in 0..n{for b in 0..n{p:=a*16+b;if kind[p]!=0{put_i64_le(mut output,k,i64(a));k++;put_i64_le(mut output,k,i64(b));k++;put_i64_le(mut output,k,kind[p]);k++;put_i64_le(mut output,k,weight[p]);k++}}};return i64(words*8)}
}
