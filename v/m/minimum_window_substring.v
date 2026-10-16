module minimum_window_substring
@[export: 'minimum_window_substring']
pub fn minimum_window_substring(v &i64,n usize,mut out &u8,cap usize)i64{
 unsafe{if v==nil||n<3||n>258||v[0]<0||v[0]>128{return -1};a:=int(v[0]);if n<a+2{return -1};mm:=v[a+1];if mm<1||mm>128{return -1};m:=int(mm);if n!=a+m+2{return -1}
 mut need:=[128]int{};for i in 0..a{if v[i+1]<0||v[i+1]>127{return -1}};for i in 0..m{c:=v[a+2+i];if c<0||c>127{return -1};need[int(c)]++}
 mut left:=0;mut best:=a+1;mut start:=0;mut missing:=m
 for right in 0..a{c:=int(v[right+1]);if need[c]>0{missing--};need[c]--;for missing==0{length:=right-left+1;if length<best{best=length;start=left};x:=int(v[left+1]);need[x]++;left++;if need[x]>0{missing++}}}
 if best==a+1{return 0};if best>cap||(best>0&&out==nil){return -2};for i in 0..best{out[i]=u8(v[start+1+i])};return i64(best)}
}
