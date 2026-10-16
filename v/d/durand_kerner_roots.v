module durand_kerner_roots

import math

struct Complex {
	r f64
	i f64
}
fn sub(a Complex,b Complex) Complex { return Complex{a.r-b.r,a.i-b.i} }
fn mul(a Complex,b Complex) Complex { return Complex{a.r*b.r-a.i*b.i,a.r*b.i+a.i*b.r} }
fn divc(a Complex,b Complex) Complex { d:=b.r*b.r+b.i*b.i; return Complex{(a.r*b.r+a.i*b.i)/d,(a.i*b.r-a.r*b.i)/d} }

@[export: 'durand_kerner_roots']
pub fn durand_kerner_roots(v &i64, n usize) f64 {
    if unsafe { v == nil } || n != 3 { return -1.0e300 }
    d,ri,part:=unsafe{v[0]},unsafe{v[1]},unsafe{v[2]}
    if d==0 || d < -4 || d > 4 || ri < 0 || ri > 2 || part < 0 || part > 1 { return -1.0e300 }
    s:=if d>0 {1.0} else {-1.0}; q:=math.sqrt(3.0)/2.0
    mut z := [3]Complex{}
    z[0]=Complex{s,0}; z[1]=Complex{-0.5*s,q*s}; z[2]=Complex{-0.5*s,-q*s}
    for _ in 0..100 {
        mut next := [3]Complex{}
        mut change:=f64(0)
        for i in 0..3 {
            mut den:=Complex{1,0}
            for j in 0..3 { if i!=j { den=mul(den,sub(z[i],z[j])) } }
            z3:=mul(mul(z[i],z[i]),z[i])
            next[i]=sub(z[i],divc(sub(z3,Complex{f64(d),0}),den))
            change=math.max(change,math.sqrt((next[i].r-z[i].r)*(next[i].r-z[i].r)+(next[i].i-z[i].i)*(next[i].i-z[i].i)))
        }
        z=next
        if change < 1.0e-14 { break }
    }
    if part==0 { return z[ri].r }
    return z[ri].i
}
