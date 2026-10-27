const MAX_TEXT:usize=32;const MAX_PATTERN:usize=8;const MAX_INPUT:usize=43;
unsafe fn store(out:*mut u8,off:usize,value:i64){let bits=value as u64;for b in 0..8{*out.add(off+b)=(bits>>(b*8)) as u8;}}
fn suffix_less(s:&[i64;33],n:usize,mut a:usize,mut b:usize)->bool{while a<n&&b<n{if s[a]!=s[b]{return s[a]<s[b]}a+=1;b+=1;}a==n&&b!=n}
#[no_mangle]
pub unsafe extern "C" fn fm_index_locate(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<5||length>MAX_INPUT{return -1}let n64=*input;if n64<1||n64>MAX_TEXT as i64||length<n64 as usize+4{return -1}let n=n64 as usize;let m_at=n+1;let m64=*input.add(m_at);if m64<1||m64>MAX_PATTERN as i64||length!=m_at+1+m64 as usize+1{return -1}let m=m64 as usize;let stride64=*input.add(length-1);if stride64<1||stride64>n64{return -1}let stride=stride64 as usize;let total=n+1;
 let mut s=[0i64;33];let mut pat=[0i64;8];for i in 0..n{let x=*input.add(i+1);if !(1..=4).contains(&x){return -1}s[i]=x;}for i in 0..m{let x=*input.add(m_at+1+i);if !(1..=4).contains(&x){return -1}pat[i]=x;}s[n]=0;
 let mut sa=[0usize;33];for i in 0..total{sa[i]=i;}for i in 1..total{let key=sa[i];let mut j=i;while j>0&&suffix_less(&s,total,key,sa[j-1]){sa[j]=sa[j-1];j-=1;}sa[j]=key;}
 let mut bwt=[0usize;33];let mut freq=[0usize;5];for i in 0..total{bwt[i]=s[(sa[i]+total-1)%total] as usize;freq[bwt[i]]+=1;}let mut c=[0usize;5];let mut sum=0;for x in 0..5{c[x]=sum;sum+=freq[x];}
 let(mut left,mut right)=(0usize,total);for j in (0..m).rev(){let sym=pat[j] as usize;let mut rl=0;let mut rr=0;for x in 0..left{if bwt[x]==sym{rl+=1;}}for x in 0..right{if bwt[x]==sym{rr+=1;}}left=c[sym]+rl;right=c[sym]+rr;if left==right{break;}}
 let mut lf=[0usize;33];let mut sampled=[false;33];let mut samples=[0usize;33];for row in 0..total{let sym=bwt[row];let rank=(0..row).filter(|&x|bwt[x]==sym).count();lf[row]=c[sym]+rank;sampled[row]=sa[row]%stride==0;samples[row]=sa[row];}
 let mut loc=[0i64;32];let mut count=0;for origin in left..right{let mut row=origin;let mut steps=0;while !sampled[row]&&steps<total{row=lf[row];steps+=1;}if !sampled[row]{return -1}let pos=(samples[row]+steps)%total;if pos>=n{return -1}loc[count]=pos as i64;count+=1;}
 let bytes=8*(count+1);if output.is_null()||capacity<bytes{return -2}store(output,0,count as i64);for i in 0..count{store(output,8*(i+1),loc[i]);}bytes as i64
}
