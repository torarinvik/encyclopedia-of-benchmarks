module max_consecutive_ones_iii
@[export: 'max_consecutive_ones_iii']
pub fn max_consecutive_ones_iii(a &i64, length usize) i64 {
 if unsafe {a==nil} || length<3 || length>1026{return -2}
 nval:=unsafe{a[0]}; if nval<1||nval>1024||length!=usize(nval+2)||unsafe{a[1]}<0||unsafe{a[1]}>nval{return -2}
 n:=int(nval);for i in 0..n {x:=unsafe{a[i+2]};if x!=0&&x!=1{return -2}}
 mut left:=0;mut zeros:=0;mut best:=0
 for right in 0..n {if unsafe{a[right+2]}==0{zeros++};for zeros>int(unsafe{a[1]}) {if unsafe{a[left+2]}==0{zeros--};left++};if right-left+1>best{best=right-left+1}}
 return i64(best)
}
