module jenkins_one_at_a_time
@[export: 'jenkins_one_at_a_time']
pub fn jenkins_one_at_a_time(v &i64,n usize) i64{if n<1||n>65{return -1};count:=unsafe{v[0]};if count<0||count>64||n!=usize(count+1){return -1};mut h:=i64(0);for i in 0..int(count){b:=unsafe{v[1+i]};if b<0||b>127{return -1};h=(h+b)&0xFFFFFFFF;h=(h+(h<<10))&0xFFFFFFFF;h=(h^(h>>6))&0xFFFFFFFF};h=(h+(h<<3))&0xFFFFFFFF;h=(h^(h>>11))&0xFFFFFFFF;h=(h+(h<<15))&0xFFFFFFFF;return h}
