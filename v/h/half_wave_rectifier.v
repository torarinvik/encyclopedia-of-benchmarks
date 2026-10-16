module half_wave_rectifier
const bad=-1.0e300
@[export:'half_wave_rectifier']
pub fn half_wave_rectifier(a &i64,n usize)f64{if unsafe{a==nil}||n!=5{return bad};unsafe{for i in 1..5{if a[i] < -1000000||a[i]>1000000{return bad}}match a[0]{0=>{if a[1]<0||a[2]<0||a[3]<0||(a[1]==0&&a[2]==0&&a[3]==0){return bad};return f64(a[4])/f64(a[1]+a[2]+a[3])},1,2=>{if a[2]!=0||a[3]!=0||a[4]!=0{return bad};return f64(a[1])*0.318},3=>{if a[2]<=0||a[3]!=0||a[4]!=0{return bad};return f64(a[1])/f64(a[2])},4,5=>{if a[2]!=0||a[3]!=0||a[4]!=0{return bad};return f64(a[1])/2.0},else=>return bad}}}
