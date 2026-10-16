module ibits
@[export: 'ibits']
pub fn ibits(v &i64,n usize)i64{if n!=1{return -1};mut x:=unsafe{v[0]};if x<0||x>=9007199254740992{return -1};mut count:=i64(0);for x!=0{count++;x=x>>1};return count}
