from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn sm_det3(m:InlineArray[Int64,9])->Int64:
    return m[0]*(m[4]*m[8]-m[5]*m[7])-m[1]*(m[3]*m[8]-m[5]*m[6])+m[2]*(m[3]*m[7]-m[4]*m[6])
fn sm_poly(m:InlineArray[Int64,9],n:Int,kind:Int)->Int64:
    var tr:Int64=0;for i in range(n):tr+=m[i*n+i]
    if kind==0:return -tr
    if n==1:return 0
    if n==2:return m[0]*m[3]-m[1]*m[2]
    if kind==1:return (m[0]*m[4]-m[1]*m[3])+(m[0]*m[8]-m[2]*m[6])+(m[4]*m[8]-m[5]*m[7])
    return -sm_det3(m)
fn sm_rank(m:InlineArray[Int64,9],n:Int)->Int:
    for r0 in range(n):for r1 in range(r0+1,n):for c0 in range(n):for c1 in range(c0+1,n):if m[r0*n+c0]*m[r1*n+c1]-m[r0*n+c1]*m[r1*n+c0]!=0:return 2
    for i in range(n*n):if m[i]!=0:return 1
    return 0
fn sm_shift(m:InlineArray[Int64,9],n:Int,num:Int64,den:Int64)->InlineArray[Int64,9]:
    var out=InlineArray[Int64,9]();for i in range(n*n):out[i]=den*m[i]
    for i in range(n):out[i*n+i]-=num
    return out
fn sm_mul(a:InlineArray[Int64,9],b:InlineArray[Int64,9],n:Int)->InlineArray[Int64,9]:
    var out=InlineArray[Int64,9]();for r in range(n):for c in range(n):for k in range(n):out[r*n+c]+=a[r*n+k]*b[k*n+c]
    return out
@export("similar_matrices")
fn similar_matrices(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>19:return -1
    let d=a[0];if d<1 or d>3 or n!=c_size_t(1+2*d*d):return -1
    var x=InlineArray[Int64,9]();var y=InlineArray[Int64,9]()
    for i in range(Int(2*d*d)):if a[i+1]< -5 or a[i+1]>5:return -1
    for i in range(Int(d*d)):x[i]=a[i+1];y[i]=a[i+1+Int(d*d)]
    let n0=Int(d);let aa=sm_poly(x,n0,0);let ab=sm_poly(x,n0,1);let ac=sm_poly(x,n0,2);if aa!=sm_poly(y,n0,0) or ab!=sm_poly(y,n0,1) or ac!=sm_poly(y,n0,2):return 0
    if n0==1:return 1
    if n0==2:
        if aa*aa-4*ab!=0:return 1
        return 1 if sm_rank(sm_shift(x,n0,-aa,2),n0)==sm_rank(sm_shift(y,n0,-aa,2),n0) else 0
    let disc=aa*aa*ab*ab-4*ab*ab*ab-4*aa*aa*aa*ac-27*ac*ac+18*aa*ab*ac
    if disc!=0:return 1
    let q=aa*aa-3*ab
    if q==0:
        let xx=sm_shift(x,n0,-aa,3);let yy=sm_shift(y,n0,-aa,3)
        if sm_rank(xx,n0)!=sm_rank(yy,n0):return 0
        return 1 if sm_rank(sm_mul(xx,xx,n0),n0)==sm_rank(sm_mul(yy,yy,n0),n0) else 0
    let num=9*ac-aa*ab;let den=2*q
    return 1 if sm_rank(sm_shift(x,n0,num,den),n0)==sm_rank(sm_shift(y,n0,num,den),n0) else 0
