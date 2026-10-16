module kinematics
@[export: 'kinematics']
pub fn kinematics(v &i64,n usize)i64{if n!=4{return -1};o:=unsafe{v[0]};x:=unsafe{v[1]};y:=unsafe{v[2]};z:=unsafe{v[3]};if o<0||o>3||x < -1000||x>1000||y < -1000||y>1000||z < -1000||z>1000{return -1};if o==0{return 2*x+2*y*z};if o==1{return 2*x*z+y*z*z};if o==2{return 2*x*x+4*y*z};return (x+y)*z}
