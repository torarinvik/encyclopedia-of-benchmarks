module lru_page_reference
import math
fn put_i64_le(mut output &u8, index int, value i64) { mut bits:=u64(value);for b in 0..8{unsafe{output[index*8+b]=u8(bits&255)};bits>>=8} }
@[export: 'lru_page_reference']
pub fn lru_page_reference(input &i64,length usize,mut output &u8,capacity usize) i64 {
 if unsafe{input==nil}||length<2{return -1};cv:=input[0];nv:=input[1];if cv<1||cv>64||(cv&(cv-1))!=0||nv<0||nv>256||length!=usize(nv)+2{return -1}
 c:=int(cv);n:=int(nv);unsafe{for i in 0..n{if input[2+i]<0||input[2+i]>1000000{return -1}};mut cache:=[64]i64{};mut events:=[512]i64{};mut used:=0
 for i in 0..n{page:=input[2+i];mut p:=0;for p<used&&cache[p]!=page{p++};mut evicted:=i64(-1);if p<used{mut j:=p;for j>0{cache[j]=cache[j-1];j--};cache[0]=page;events[2*i]=1}else{if used==c{evicted=cache[used-1];used--};mut j:=used;for j>0{cache[j]=cache[j-1];j--};cache[0]=page;used++;events[2*i]=0};events[2*i+1]=evicted}
 words:=2*n+2+used;if output==nil||capacity<words*8{return -2};put_i64_le(mut output,0,i64(n));for i in 0..2*n{put_i64_le(mut output,i+1,events[i])};put_i64_le(mut output,2*n+1,i64(used));for i in 0..used{put_i64_le(mut output,2*n+2+i,cache[i])};return i64(words*8)}
}
