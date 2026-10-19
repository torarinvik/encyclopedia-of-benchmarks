from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, isfinite, abs
fn qr2_det(m:InlineArray[Float64,16],n:Int)->Float64:
    var a=m;var det:Float64=1.0
    for k in range(n):
        var pivot=k
        for r in range(k+1,n):if abs(a[r*n+k])>abs(a[pivot*n+k]):pivot=r
        if a[pivot*n+k]==0.0:return 0.0
        if pivot!=k:
            for c in range(n):let t=a[k*n+c];a[k*n+c]=a[pivot*n+c];a[pivot*n+c]=t
            det= -det
        let x=a[k*n+k];det*=x
        for r in range(k+1,n):
            let f=a[r*n+k]/x
            for c in range(k+1,n):a[r*n+c]-=f*a[k*n+c]
    return det
@export("qr_decomposition")
fn qr_decomposition(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<2 or n>17:return -1
    let d0=Int64(a[0]);if d0<1 or d0>4 or Float64(d0)!=a[0] or n!=c_size_t(1+d0*d0):return -1
    let d=Int(d0);var mat=InlineArray[Float64,16]();var q=InlineArray[Float64,16]();var r=InlineArray[Float64,16]();var minor=InlineArray[Float64,16]()
    for i in range(d*d):
        let x=a[i+1]
        if not isfinite(x) or Float64(Int64(x))!=x or x< -1.0 or x>1.0:return -1
        mat[i]=x;minor[i]=x
    # Exact leading-principal-minor check is done using pivots of each prefix.
    for size in range(1,d+1):
        var m=InlineArray[Float64,16]()
        for i in range(size):for j in range(size):m[i*size+j]=mat[i*d+j]
        if qr2_det(m,size)==0.0:return -1
    for col in range(d):
        var v=InlineArray[Float64,4]();var norm2:Float64=0.0
        for row in range(d):v[row]=mat[row*d+col]
        for prev in range(col):
            var dot:Float64=0.0
            for row in range(d):dot+=q[row*d+prev]*v[row]
            for row in range(d):v[row]-=dot*q[row*d+prev]
        for row in range(d):norm2+=v[row]*v[row]
        let norm=sqrt(norm2)
        if norm==0.0 or not isfinite(norm):return -1
        for row in range(d):q[row*d+col]=v[row]/norm
    for i in range(d):for j in range(d):
        if i<=j:for k in range(d):r[i*d+j]+=q[k*d+i]*mat[k*d+j]
    var recon:Float64=0.0;var orth:Float64=0.0;var lower:Float64=0.0
    for i in range(d):for j in range(d):
        var prod:Float64=0.0;var gram:Float64=0.0
        for k in range(d):prod+=q[i*d+k]*r[k*d+j];gram+=q[k*d+i]*q[k*d+j]
        let e=mat[i*d+j]-prod;recon+=e*e
        let z=gram-(1.0 if i==j else 0.0);orth+=z*z
        if i>j:lower+=r[i*d+j]*r[i*d+j]
    let result0=sqrt(recon);let result1=sqrt(orth);let result2=sqrt(lower)
    if not isfinite(result0) or not isfinite(result1) or not isfinite(result2):return -1
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<3:return -2
    o[0]=result0;o[1]=result1;o[2]=result2;return 3
