fn scan(s &u8, lo int, hi int, mut h u64) { mut depth:=0; mut begin:=0; for i:=lo;i<hi;i++ { if unsafe{s[i]}==u8(60) { if depth==0 { begin=i }; depth++ } else if unsafe{s[i]}==u8(62) { depth--; if depth==0 { for j:=begin;j<=i;j++ { h=(h*257+u64(unsafe{s[j]})+1)%1000000007 }; scan(unsafe{&s[begin+1]},0,i-begin-1,mut h) } } } }
@[export: 'parse_nested_brackets']
pub fn parse_nested_brackets(v &i64, n usize) i64 { unsafe { if v==nil||n<1||n>129||v[0]<0||v[0]>128||n!=usize(v[0]+1){return -1};len:=int(v[0]);mut s:=[128]u8{};mut d:=0;for i in 0..len { x:=v[i+1];if x<0||x>127{return -1};s[i]=u8(x);if s[i]==u8(60){d++}else if s[i]==u8(62){d--;if d<0{return -1}} };if d!=0{return -1};mut h:=u64(0);scan(&s[0],0,len,mut h);return i64(h) } }

