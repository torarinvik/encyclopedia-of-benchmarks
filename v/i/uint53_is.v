module uint53_is
@[export: 'uint53_is']
pub fn uint53_is(v &i64,n usize)i64{if n!=1{return -1};x:=unsafe{v[0]};return if x>=0&&x<9007199254740992{1}else{0}}
