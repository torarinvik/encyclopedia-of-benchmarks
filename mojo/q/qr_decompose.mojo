from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, isfinite, abs
fn qr_det(m:InlineArray[Float64,16],n:Int)->Float64:
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
@export("qr_decompose")
fn qr_decompose(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n<2 or n>17:return -1
    let d=Int64(a[0])
    if d<1 or d>4 or Float64(d)!=a[0] or n!=c_size_t(1+d*d):return -1
    var mat=InlineArray[Float64,16]();var q=InlineArray[Float64,16]();var r=InlineArray[Float64,16]()
    for i in range(Int(d*d)):
        let x=a[i+1]
        if not isfinite(x) or Float64(Int64(x))!=x or x< -4.0 or x>4.0:return -1
        mat[i]=x
    if qr_det(mat,Int(d))==0.0:return -1
    for col in range(Int(d)):
        var residual=InlineArray[Float64,4]();var original=InlineArray[Float64,4]();var norm2:Float64=0.0
        for row in range(Int(d)):original[row]=mat[row*Int(d)+col];residual[row]=original[row]
        for prev in range(col):
            var dot:Float64=0.0;var qnorm:Float64=0.0
            for row in range(Int(d)):
                let qv=q[row*Int(d)+prev];dot+=original[row]*qv;qnorm+=qv*qv
            let coef=dot/qnorm
            for row in range(Int(d)):residual[row]-=coef*q[row*Int(d)+prev]
        for row in range(Int(d)):norm2+=residual[row]*residual[row]
        let norm=sqrt(norm2)
        if not isfinite(norm) or norm==0.0:return -1
        for row in range(Int(d)):q[row*Int(d)+col]=residual[row]/norm
    for row in range(Int(d)):
        for col in range(Int(d)):
            if col<row:r[row*Int(d)+col]=0.0
            else:
                var dot:Float64=0.0
                for k in range(Int(d)):dot+=q[k*Int(d)+row]*mat[k*Int(d)+col]
                r[row*Int(d)+col]=dot
    let need=Int(d*d*2)
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(need):return -2
    for i in range(Int(d*d)):o[i]=q[i];o[Int(d*d)+i]=r[i]
    return need
