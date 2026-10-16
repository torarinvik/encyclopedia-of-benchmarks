module prefix_function
@[export: 'prefix_function']
pub fn prefix_function(v &i64,n usize,mut out &u8,cap usize)i64{unsafe{if v==nil||n<1||n>4097||v[0]<0||v[0]>4096||n!=usize(v[0]+1){return -1};length:=int(v[0]);for i in 0..length{if v[i+1]<0||v[i+1]>127{return -1}};bytes:=length*4;if bytes>cap||(bytes>0&&out==nil){return -2};mut pi:=[4096]int{};for i in 1..length{mut j:=pi[i-1];for j>0&&v[i+1]!=v[j+1]{j=pi[j-1]};if v[i+1]==v[j+1]{j++};pi[i]=j};for i in 0..length{x:=u32(pi[i]);for k in 0..4{out[4*i+k]=u8((x>>(8*k))&255)}};return i64(bytes)}}
