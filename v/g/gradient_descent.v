module gradient_descent
const invalid = -1.0e300
@[export: 'gradient_descent']
pub fn gradient_descent(v &i64, length usize) f64 {
 if unsafe {v==nil} || length<5 || length>68 {return invalid}
 unsafe { d:=v[0]; selected:=v[1]; rate:=v[2]; iterations:=v[3]
 if d<1 || d>64 || selected<0 || selected>=d || length!=usize(4+d) || rate<1 || rate>500000 || iterations<0 || iterations>10000 {return invalid}
 mut x:=[]f64{len:int(d)}; for i in 0..int(d) {if v[4+i]< -10 || v[4+i]>10{return invalid}; x[i]=f64(v[4+i])}
 alpha:=f64(rate)/1_000_000.0
 for _ in 0..int(iterations) {mut g:=[]f64{len:int(d)}; for i in 0..int(d) {g[i]=2.0*x[i]}; for i in 0..int(d) {x[i]-=alpha*g[i]}}
 return x[int(selected)] }
}
