from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt, fabs, isfinite
fn pca_ri(matrix:InlineArray[Float64,16],dim:Int,inout eig:Float64,inout vec:InlineArray[Float64,4])->Bool:
    var x=InlineArray[Float64,4](fill=1.0);var prev=InlineArray[Float64,4](fill=0.0);var nxt=InlineArray[Float64,4](fill=0.0);var converged=False
    for it in range(1000):
        for i in range(dim):prev[i]=x[i]
        for i in range(dim):
            nxt[i]=0.0
            for j in range(dim):nxt[i]+=matrix[i*dim+j]*x[j]
        var norm2=0.0
        for i in range(dim):norm2+=nxt[i]*nxt[i]
        let norm=sqrt(norm2)
        if not isfinite(norm) or norm<=1e-10:return False
        for i in range(dim):x[i]=nxt[i]/norm
        var diff=0.0
        for i in range(dim):diff=max(diff,fabs(x[i]-prev[i]))
        if diff<1e-10:converged=True;break
    if not converged:return False
    var numerator=0.0;var denominator=0.0
    for i in range(dim):
        var row=0.0
        for j in range(dim):row+=matrix[i*dim+j]*x[j]
        numerator+=row*x[i];denominator+=x[i]*x[i]
    if denominator==0 or not isfinite(numerator):return False
    eig=numerator/denominator
    if not isfinite(eig):return False
    for i in range(dim):vec[i]=x[i]
    return True
@export("principal_component_analysis")
fn principal_component_analysis(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<3 or n>35:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    if v[0]<2 or v[0]>8 or v[0]!=Float64(Int(v[0])) or v[1]<2 or v[1]>4 or v[1]!=Float64(Int(v[1])) or v[2]<1 or v[2]>v[1] or v[2]!=Float64(Int(v[2])):return -1
    let rows=Int(v[0]);let cols=Int(v[1]);let comps=Int(v[2])
    if n!=c_size_t(3+rows*cols):return -1
    var data=InlineArray[Float64,32](fill=0.0);var means=InlineArray[Float64,4](fill=0.0)
    for i in range(rows*cols):if v[3+i]<-100 or v[3+i]>100:return -1;else:data[i]=v[3+i]
    for r in range(rows):for c in range(cols):means[c]+=data[r*cols+c]
    for c in range(cols):means[c]/=Float64(rows)
    var centered=InlineArray[Float64,32](fill=0.0)
    for r in range(rows):for c in range(cols):centered[r*cols+c]=data[r*cols+c]-means[c]
    var matrix=InlineArray[Float64,16](fill=0.0)
    for i in range(cols):for j in range(cols):
        var sum=0.0
        for r in range(rows):sum+=centered[r*cols+i]*centered[r*cols+j]
        matrix[i*cols+j]=sum/Float64(rows)
    var vectors=InlineArray[Float64,16](fill=0.0)
    for k in range(comps):
        var eig=0.0;var vec=InlineArray[Float64,4](fill=0.0)
        if not pca_ri(matrix,cols,eig,vec):return -1
        for i in range(cols):vectors[k*cols+i]=vec[i]
        for i in range(cols):for j in range(cols):matrix[i*cols+j]-=eig*vec[i]*vec[j]
    var result=InlineArray[Float64,34](fill=0.0);result[0]=Float64(rows);result[1]=Float64(comps);var pos=2
    for r in range(rows):for k in range(comps):
        var score=0.0
        for c in range(cols):score+=vectors[k*cols+c]*centered[r*cols+c]
        if not isfinite(score):return -1
        result[pos]=score;pos+=1
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(pos):return -2
    for i in range(pos):out[i]=result[i]
    return Int64(pos)
