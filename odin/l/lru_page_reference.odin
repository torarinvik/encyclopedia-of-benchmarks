package lru_page_reference
import "core:c"
put_i64_le :: proc "contextless"(value:i64,output:[^]u8,index:usize){bits:=transmute(u64)value;for b:=0;b<8;b+=1{output[index*8+b]=u8(bits>>u64(8*b))}}
@(export)
lru_page_reference :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2 do return -1
 cv,nv:=input[0],input[1];if cv<1||cv>64||(cv&(cv-1))!=0||nv<0||nv>256||length!=usize(nv)+2 do return -1
 c,n:=usize(cv),usize(nv);for i:usize=0;i<n;i+=1{if input[2+i]<0||input[2+i]>1000000 do return -1}
 cache:[64]i64;events:[512]i64;used:usize=0
 for i:usize=0;i<n;i+=1{page:=input[2+i];evicted:i64=-1;p:usize=0;for p<used&&cache[p]!=page{p+=1};if p<used{j:=p;for j>0{cache[j]=cache[j-1];j-=1};cache[0]=page;events[2*i]=1}else{if used==c{evicted=cache[used-1];used-=1};j:=used;for j>0{cache[j]=cache[j-1];j-=1};cache[0]=page;used+=1;events[2*i]=0};events[2*i+1]=evicted}
 words:=2*n+2+used;if output==nil||capacity<words*8 do return -2
 put_i64_le(i64(n),output,0);for i:usize=0;i<2*n;i+=1{put_i64_le(events[i],output,i+1)};put_i64_le(i64(used),output,2*n+1);for i:usize=0;i<used;i+=1{put_i64_le(cache[i],output,2*n+2+i)}
 return i64(words*8)
}
