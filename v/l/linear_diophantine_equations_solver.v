module linear_diophantine_equations_solver
@[export: 'linear_diophantine_equations_solver']
pub fn linear_diophantine_equations_solver(v &i64,n usize)i64{
 if n!=3{return -1};a:=unsafe{v[0]};b:=unsafe{v[1]};c:=unsafe{v[2]};if a< -1000||a>1000||b< -1000||b>1000||c< -10000||c>10000{return -1}
 if a==0&&b==0{return if c==0{-3}else{-2}};if a==0{return if c%b==0{20000003*10000001+(c/b+10000001)}else{-2}};if b==0{return if c%a==0{(c/a+10000001)*20000003+10000001}else{-2}}
 mut or:=a;mut r:=b;mut os:=i64(1);mut s:=i64(0);mut ot:=i64(0);mut t:=i64(1)
 for r!=0{q:=or/r;z:=or-q*r;or=r;r=z;z=os-q*s;os=s;s=z;z=ot-q*t;ot=t;t=z}
 if c%or!=0{return -2};x:=os*(c/or);y:=ot*(c/or);return (x+10000001)*20000003+(y+10000001)
}
