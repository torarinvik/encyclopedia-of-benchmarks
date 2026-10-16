module kth_next_greater_element
@[export: 'kth_next_greater_element']
pub fn kth_next_greater_element(v &i64,n usize)i64{if n<2||n>8{return -1};k:=unsafe{v[0]};if k<1||k>7{return -1};for q in 1..n{x:=unsafe{v[q]};if x< -15||x>15{return -1}};m:=n-1;mut count:=i64(0);for i in 0..m{mut cur:=unsafe{v[i+1]};mut pos:=i+1;mut ok:=true;for _ in 0..k{for pos<m&&unsafe{v[pos+1]}<=cur{pos++};if pos==m{ok=false;break};cur=unsafe{v[pos+1]};pos++};if ok{count++}};return count}
