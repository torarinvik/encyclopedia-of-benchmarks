fn eg(a:i64,b:i64)->(i64,i64,i64){if b==0{return(a,1,0)}let(g,x1,y1)=eg(b,a%b);(g,y1,x1-(a/b)*y1)}
fn pack(x:i64,y:i64)->i64{(x+10_000_001)*20_000_003+(y+10_000_001)}
#[no_mangle]
pub extern "C" fn linear_diophantine_equations_solver(v:*const i64,n:usize)->i64{if v.is_null()||n!=3{return -1}let a=unsafe{*v};let b=unsafe{*v.add(1)};let c=unsafe{*v.add(2)};if a.abs()>1000||b.abs()>1000||c.abs()>10000{return -1}if a==0&&b==0{return if c==0{-3}else{-2}}if a==0{return if c%b==0{pack(0,c/b)}else{-2}}if b==0{return if c%a==0{pack(c/a,0)}else{-2}}let(g,x,y)=eg(a,b);if c%g!=0{return -2}pack(x*(c/g),y*(c/g))}
