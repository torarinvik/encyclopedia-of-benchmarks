module iterating_through_submasks
@[export: 'iterating_through_submasks']
pub fn iterating_through_submasks(v &i64,n usize)i64{if n!=1{return -1};mask:=unsafe{v[0]};if mask<1||mask>4095{return -1};mut submask:=mask;mut count:=i64(0);for submask!=0{count++;submask=(submask-1)&mask};return count}
