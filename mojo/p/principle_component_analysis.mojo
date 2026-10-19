from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, fabs, isfinite
fn pca_jacobi(inout a:InlineArray[Float64,16],inout vec:InlineArray[Float64,16],n:Int)->Bool:
    for i in range(n):for j in range(n):vec[i*4+j]=1.0 if i==j else 0.0
    var done=False
    for sweep in range(65):
        var largest=0.0
        for p in range(n):for q in range(p+1,n):largest=max(largest,fabs(a[p*4+q]))
        if largest<=1e-14:done=True;break
        if sweep==64:break
        for p in range(n):for q in range(p+1,n):
            let apq=a[p*4+q]
            if fabs(apq)<=1e-14:continue
            let tau=(a[q*4+q]-a[p*4+p])/(2.0*apq);let sign=1.0 if tau>=0 else -1.0
            let t=sign/(fabs(tau)+sqrt(1.0+tau*tau));let c=1.0/sqrt(1.0+t*t);let s=t*c
            let app=a[p*4+p];let aqq=a[q*4+q];a[p*4+p]=app-t*apq;a[q*4+q]=aqq+t*apq;a[p*4+q]=0.0;a[q*4+p]=0.0
            for r in range(n):
                if r!=p and r!=q:
                    let rp=a[r*4+p];let rq=a[r*4+q]
                    a[r*4+p]=c*rp-s*rq;a[p*4+r]=a[r*4+p];a[r*4+q]=s*rp+c*rq;a[q*4+r]=a[r*4+q]
                let vp=vec[r*4+p];let vq=vec[r*4+q]
                vec[r*4+p]=c*vp-s*vq;vec[r*4+q]=s*vp+c*vq
    return done
@export("principle_component_analysis")
fn principle_component_analysis(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<3 or n>35:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    if v[0]<3 or v[0]>8 or v[0]!=Float64(Int(v[0])) or v[1]<2 or v[1]>4 or v[1]!=Float64(Int(v[1])) or v[2]<1 or v[2]>4 or v[2]!=Float64(Int(v[2])):return -1
    let rows=Int(v[0]);let cols=Int(v[1]);let comps=Int(v[2])
    if rows<=cols or comps>cols or n!=c_size_t(3+rows*cols):return -1
    var data=InlineArray[Float64,32](fill=0.0);var means=InlineArray[Float64,4](fill=0.0)
    for r in range(rows):for c in range(cols):
        let x=v[3+r*cols+c]
        if x!=Float64(Int(x)) or x< -9 or x>9:return -1
        data[r*cols+c]=x;means[c]+=x
    for c in range(cols):means[c]/=Float64(rows)
    var variance=InlineArray[Float64,4](fill=0.0)
    for r in range(rows):for c in range(cols):let d=data[r*cols+c]-means[c];variance[c]+=d*d
    var scale=InlineArray[Float64,4](fill=0.0)
    for c in range(cols):variance[c]/=Float64(rows);if variance[c]<=0:return -1;scale[c]=sqrt(variance[c])
    var standardized=InlineArray[Float64,32](fill=0.0);var mean2=InlineArray[Float64,4](fill=0.0)
    for r in range(rows):for c in range(cols):standardized[r*cols+c]=(data[r*cols+c]-means[c])/scale[c];mean2[c]+=standardized[r*cols+c]
    for c in range(cols):mean2[c]/=Float64(rows)
    var cov=InlineArray[Float64,16](fill=0.0)
    for i in range(cols):for j in range(cols):
        var sum=0.0
        for r in range(rows):sum+=(standardized[r*cols+i]-mean2[i])*(standardized[r*cols+j]-mean2[j])
        cov[i*4+j]=sum/Float64(rows-1)
    var vec=InlineArray[Float64,16](fill=0.0)
    if not pca_jacobi(cov,vec,cols):return -1
    var eigen=InlineArray[Float64,4](fill=0.0)
    for i in range(cols):eigen[i]=cov[i*4+i]
    for i in range(cols):for j in range(i+1,cols):if eigen[j]>eigen[i]:let t=eigen[i];eigen[i]=eigen[j];eigen[j]=t;for r in range(cols):let z=vec[r*4+i];vec[r*4+i]=vec[r*4+j];vec[r*4+j]=z
    for i in range(cols):if eigen[i]<=0:return -1
    for i in range(cols-1):if eigen[i]-eigen[i+1]<=1e-8:return -1
    var total=0.0
    for i in range(cols):total+=eigen[i]
    var scores=InlineArray[Float64,32](fill=0.0)
    for k in range(comps):
        for r in range(rows):for c in range(cols):scores[k*8+r]+=(standardized[r*cols+c]-mean2[c])*vec[c*4+k]
        var pivot=0
        for r in range(1,rows):if fabs(scores[k*8+r])>fabs(scores[k*8+pivot]):pivot=r
        if scores[k*8+pivot]<0:for r in range(rows):scores[k*8+r]=-scores[k*8+r]
    var result=InlineArray[Float64,38](fill=0.0);result[0]=Float64(rows);result[1]=Float64(comps);var pos=2
    for r in range(rows):for k in range(comps):result[pos]=scores[k*8+r];pos+=1
    for k in range(comps):result[pos]=eigen[k]/total;pos+=1
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):out[i]=result[i]
    return Int64(pos)
