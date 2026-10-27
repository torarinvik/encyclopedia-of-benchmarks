package fm_index_locate
import "core:c"
MAX_TEXT :: 32
MAX_PATTERN :: 8
MAX_INPUT :: 43
ALPHABET :: 5
suffix_less :: proc(s:[^]i64,n,a0,b0:int)->bool{a:=a0;b:=b0;for a<n&&b<n{if s[a]!=s[b]{return s[a]<s[b]};a+=1;b+=1};return a==n&&b!=n}
store_i64_le :: proc(out:[^]u8,off:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[off+b]=u8(bits&255);bits>>=8}}
@(export)
fm_index_locate :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<5||length>MAX_INPUT do return -1
 n64:=input[0];if n64<1||n64>MAX_TEXT||length<c.size_t(n64+4) do return -1
 n:=int(n64);m_at:=n+1;m64:=input[m_at];if m64<1||m64>MAX_PATTERN||int(length)!=m_at+2+int(m64) do return -1
 m:=int(m64);stride64:=input[int(length)-1];if stride64<1||stride64>n64 do return -1
 stride:=int(stride64);total:=n+1
 s:[MAX_TEXT+1]i64;pat:[MAX_PATTERN]i64
 for i:=0;i<n;i+=1{ x:=input[i+1];if x<1||x>4 do return -1;s[i]=x }
 for i:=0;i<m;i+=1{ x:=input[m_at+1+i];if x<1||x>4 do return -1;pat[i]=x };s[n]=0
 sa:[MAX_TEXT+1]int;for i:=0;i<total;i+=1{sa[i]=i}
 for i:=1;i<total;i+=1{key:=sa[i];j:=i;for j>0&&suffix_less(&s[0],total,key,sa[j-1]){sa[j]=sa[j-1];j-=1};sa[j]=key}
 bwt:[MAX_TEXT+1]int;freq:[ALPHABET]int
 for i:=0;i<total;i+=1{bwt[i]=int(s[(sa[i]+total-1)%total]);freq[bwt[i]]+=1}
 C:[ALPHABET]int;acc:=0;for cidx:=0;cidx<ALPHABET;cidx+=1{C[cidx]=acc;acc+=freq[cidx]}
 left:=0;right:=total
 for j:=m-1;j>=0;j-=1{sym:=int(pat[j]);rl:=0;rr:=0;for x:=0;x<left;x+=1{if bwt[x]==sym{rl+=1}};for x:=0;x<right;x+=1{if bwt[x]==sym{rr+=1}};left=C[sym]+rl;right=C[sym]+rr;if left==right{break}}
 LF:[MAX_TEXT+1]int;sampled:[MAX_TEXT+1]bool;samples:[MAX_TEXT+1]int
 for row:=0;row<total;row+=1{sym:=bwt[row];rank:=0;for x:=0;x<row;x+=1{if bwt[x]==sym{rank+=1}};LF[row]=C[sym]+rank;sampled[row]=sa[row]%stride==0;samples[row]=sa[row]}
 loc:[MAX_TEXT]i64;count:=0
 for origin:=left;origin<right;origin+=1{row:=origin;steps:=0;for !sampled[row]&&steps<total{row=LF[row];steps+=1};if !sampled[row] do return -1;pos:=(samples[row]+steps)%total;if pos>=n do return -1;loc[count]=i64(pos);count+=1}
 bytes:=8*(count+1);if output==nil||capacity<c.size_t(bytes) do return -2
 store_i64_le(output,0,i64(count));for i:=0;i<count;i+=1{store_i64_le(output,8*(i+1),loc[i])};return i64(bytes)
}
