@[export: 'fm_index_locate']
pub fn fm_index_locate(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
 if input==nil||length<5||length>43{return -1}n64:=input[0]
 if n64<1||n64>32||length<usize(n64+4){return -1}n:=int(n64);m_at:=n+1;m64:=input[m_at]
 if m64<1||m64>8||length!=usize(m_at+2+m64){return -1}m:=int(m64);stride64:=input[length-1]
 if stride64<1||stride64>n64{return -1}stride:=int(stride64);total:=n+1
 mut s:=[]i64{len:total,init:0};mut pat:=[]i64{len:m,init:0}
 for i in 0..n{x:=input[i+1];if x<1||x>4{return -1};s[i]=x}
 for i in 0..m{x:=input[m_at+1+i];if x<1||x>4{return -1};pat[i]=x}s[n]=0
 mut sa:=[]int{len:total,init:0};for i in 0..total{sa[i]=i}
 for i in 1..total{key:=sa[i];mut j:=i;for j>0&&suffix_less(s,key,sa[j-1]){sa[j]=sa[j-1];j--}sa[j]=key}
 mut bwt:=[]int{len:total,init:0};mut freq:=[]int{len:5,init:0}
 for i in 0..total{bwt[i]=int(s[(sa[i]+total-1)%total]);freq[bwt[i]]++}
 mut c:=[]int{len:5,init:0};mut acc:=0;for x in 0..5{c[x]=acc;acc+=freq[x]}
 mut left:=0;mut right:=total
 for j:=m-1;j>=0;j--{sym:=int(pat[j]);mut rl:=0;mut rr:=0;for x in 0..left{if bwt[x]==sym{rl++}}for x in 0..right{if bwt[x]==sym{rr++}}left=c[sym]+rl;right=c[sym]+rr;if left==right{break}}
 mut lf:=[]int{len:total,init:0};mut sampled:=[]bool{len:total,init:false};mut samples:=[]int{len:total,init:0}
 for row in 0..total{sym:=bwt[row];mut rank:=0;for x in 0..row{if bwt[x]==sym{rank++}}lf[row]=c[sym]+rank;sampled[row]=sa[row]%stride==0;samples[row]=sa[row]}
 mut loc:=[]i64{len:32,init:0};mut count:=0
 for origin in left..right{mut row:=origin;mut steps:=0;for !sampled[row]&&steps<total{row=lf[row];steps++}if !sampled[row]{return -1}pos:=(samples[row]+steps)%total;if pos>=n{return -1}loc[count]=i64(pos);count++}
 bytes:=8*(count+1);if output==nil||capacity<usize(bytes){return -2}
 values:=[]i64{len:count+1,init:0};values[0]=i64(count);for i in 0..count{values[i+1]=loc[i]}
 for idx,value in values{bits:=u64(value);for b in 0..8{output[8*idx+b]=u8((bits>>(8*b))&255)}}return i64(bytes)
 }
}
fn suffix_less(s []i64,a0 int,b0 int) bool{mut a:=a0;mut b:=b0;for a<s.len&&b<s.len{if s[a]!=s[b]{return s[a]<s[b]}a++;b++}return a==s.len&&b!=s.len}
