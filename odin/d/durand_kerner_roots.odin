package durand_kerner_roots

import "core:c"
import "core:math"

C :: struct { r, i: f64 }
sub :: proc "contextless" (a,b:C)->C { return {a.r-b.r,a.i-b.i} }
mul :: proc "contextless" (a,b:C)->C { return {a.r*b.r-a.i*b.i,a.r*b.i+a.i*b.r} }
divc :: proc "contextless" (a,b:C)->C { d:=b.r*b.r+b.i*b.i; return {(a.r*b.r+a.i*b.i)/d,(a.i*b.r-a.r*b.i)/d} }

@(export)
durand_kerner_roots :: proc "c" (v: [^]i64, n: c.size_t) -> f64 {
    if v == nil || n != 3 do return -1.0e300
    d, ri, part := v[0],v[1],v[2]
    if d==0 || d < -4 || d > 4 || ri < 0 || ri > 2 || part < 0 || part > 1 do return -1.0e300
    s: f64
    if d>0 { s=1.0 } else { s=-1.0 }
    q:=math.sqrt(3.0)/2.0
    z:=[3]C{{s,0},{-0.5*s,q*s},{-0.5*s,-q*s}}
    for it:=0; it<100; it+=1 {
        next:=z; change:=0.0
        for i:=0; i<3; i+=1 {
            den:=C{1,0}
            for j:=0; j<3; j+=1 { if i!=j { den=mul(den,sub(z[i],z[j])) } }
            z3:=mul(mul(z[i],z[i]),z[i])
            next[i]=sub(z[i],divc(sub(z3,C{f64(d),0}),den))
            change=math.max(change,math.sqrt((next[i].r-z[i].r)*(next[i].r-z[i].r)+(next[i].i-z[i].i)*(next[i].i-z[i].i)))
        }
        z=next
        if change<1.0e-14 do break
    }
    if part==0 do return z[ri].r
    return z[ri].i
}
