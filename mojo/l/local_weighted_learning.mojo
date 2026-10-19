from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import abs,exp,isfinite,trunc

fn lwl_grid(x:Float64,lo:Float64,hi:Float64)->Bool:
    if not isfinite(x) or x<lo or x>hi:return False
    let z=x*16.0
    return isfinite(z) and trunc(z)==z
fn lwl_solve(mut a:InlineArray[Float64,16],mut rhs:InlineArray[Float64,4],d:Int,mut sol:InlineArray[Float64,4])->Bool:
    var scale=0.0
    for i in range(d):
        let x=abs(a[i*d+i])
        if not isfinite(x):return False
        if x>scale:scale=x
    if scale==0.0 or not isfinite(scale):return False
    for pc in range(d):
        var pr=pc;var pm=abs(a[pc*d+pc])
        for r in range(pc+1,d):
            let cm=abs(a[r*d+pc])
            if not isfinite(cm):return False
            if cm>pm:pr=r;pm=cm
        if not isfinite(pm) or pm<=0.000003814697265625*scale:return False
        if pr!=pc:
            for c in range(d):
                let tmp=a[pc*d+c];a[pc*d+c]=a[pr*d+c];a[pr*d+c]=tmp
            let temp=rhs[pc];rhs[pc]=rhs[pr];rhs[pr]=temp
        let pivot=a[pc*d+pc]
        for r in range(pc+1,d):
            let factor=a[r*d+pc]/pivot
            if not isfinite(factor):return False
            a[r*d+pc]=0.0
            for c in range(pc+1,d):
                let product=factor*a[pc*d+c];a[r*d+c]=a[r*d+c]-product
                if not isfinite(a[r*d+c]):return False
            let product=factor*rhs[pc];rhs[r]=rhs[r]-product
            if not isfinite(rhs[r]):return False
    for rr in range(d):
        let r=d-1-rr;var residual=rhs[r]
        for c in range(r+1,d):
            let product=a[r*d+c]*sol[c];residual=residual-product
        let diagonal=a[r*d+r]
        if not isfinite(residual) or diagonal==0.0 or not isfinite(diagonal):return False
        sol[r]=residual/diagonal
        if not isfinite(sol[r]):return False
    return True

@export("local_weighted_learning")
fn local_weighted_learning(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<3 or n>84:return -1
    let nv=v[0];let dv=v[1]
    if not isfinite(nv) or nv<2 or nv>16 or trunc(nv)!=nv or not isfinite(dv) or dv<1 or dv>4 or trunc(dv)!=dv:return -1
    let m=Int(nv);let d=Int(dv)
    if d>m or not lwl_grid(v[2],2.0,8.0) or n!=c_size_t(3+m*d+m):return -1
    var x=InlineArray[Float64,64](fill=0.0);var y=InlineArray[Float64,16](fill=0.0);var p=3
    for r in range(m):
        for c in range(d):
            if not lwl_grid(v[p],-4.0,4.0):return -1
            x[r*4+c]=v[p];p+=1
    for r in range(m):
        if not lwl_grid(v[p],-8.0,8.0):return -1
        y[r]=v[p];p+=1
    let tau=v[2];var staged=InlineArray[Float64,16](fill=0.0)
    for query in range(m):
        var weights=InlineArray[Float64,16](fill=0.0)
        for row in range(m):
            var ds=0.0
            for f in range(d):
                let delta=x[query*4+f]-x[row*4+f];let sq=delta*delta;ds=ds+sq
            let tau2=tau*tau;let denom=(-2.0)*tau2;let exponent=ds/denom
            weights[row]=exp(exponent)
            if not isfinite(weights[row]) or weights[row]<=0.0:return -1
        var normal=InlineArray[Float64,16](fill=0.0);var rhs=InlineArray[Float64,4](fill=0.0)
        for row in range(m):
            var wx=InlineArray[Float64,4](fill=0.0)
            for f in range(d):wx[f]=weights[row]*x[row*4+f]
            let wy=weights[row]*y[row]
            for a in range(d):
                let product=x[row*4+a]*wy;rhs[a]=rhs[a]+product
                for b in range(d):
                    let q=x[row*4+a]*wx[b];normal[a*d+b]=normal[a*d+b]+q
        var coeff=InlineArray[Float64,4](fill=0.0)
        if not lwl_solve(normal,rhs,d,coeff):return -1
        var pred=0.0
        for f in range(d):
            let product=x[query*4+f]*coeff[f];pred=pred+product
        if not isfinite(pred):return -1
        staged[query]=pred
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(m):return -2
    for i in range(m):out[i]=staged[i]
    return Int64(m)
