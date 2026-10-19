from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mu_orth(g:InlineArray[Float64,16],rows:Int,cols:Int,steps:Int)->InlineArray[Float64,16]:
    let tr=rows<cols;let wr=if tr:cols else:rows;let wc=if tr:rows else:cols
    var a=InlineArray[Float64,16](fill=0.0)
    for r in range(rows):for c in range(cols):if tr:a[c*4+r]=g[r*4+c] else:a[r*4+c]=g[r*4+c]
    for _ in range(steps):
        var gram=InlineArray[Float64,16](fill=0.0);var prod=InlineArray[Float64,16](fill=0.0)
        for l in range(wc):for k in range(wc):var s=0.0;for r in range(wr):s+=a[r*4+l]*a[r*4+k];gram[l*4+k]=s
        for r in range(wr):for c in range(wc):var s=0.0;for k in range(wc):s+=a[r*4+k]*gram[k*4+c];prod[r*4+c]=s
        for r in range(wr):for c in range(wc):a[r*4+c]=1.5*a[r*4+c]-0.5*prod[r*4+c]
    var res=InlineArray[Float64,16](fill=0.0)
    for r in range(rows):for c in range(cols):res[r*4+c]=if tr:a[c*4+r] else:a[r*4+c]
    return res
@export("muon_optimizer")
fn muon_optimizer(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<10 or n>272:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let groups=Int(v[0]);let rows=Int(v[1]);let cols=Int(v[2]);let calls=Int(v[3]);let steps=Int(v[4]);let size=rows*cols
    if v[0]!=Float64(groups) or v[1]!=Float64(rows) or v[2]!=Float64(cols) or v[3]!=Float64(calls) or v[4]!=Float64(steps) or groups<1 or groups>4 or rows<1 or rows>4 or cols<1 or cols>4 or calls<1 or calls>8 or steps<0 or steps>5 or size>16 or groups*size>32 or calls<groups or Int(n)!=7+calls*(1+2*size):return -1
    let rate=v[5];let momentum=v[6];if rate<0.0 or rate>0.25 or momentum<0.0 or momentum>0.99:return -1
    var ids=InlineArray[Int64,8](fill=0);var params=InlineArray[Float64,128](fill=0.0);var grads=InlineArray[Float64,128](fill=0.0);var seen=InlineArray[Int64,4](fill=0);var p=7
    for e in range(calls):
        let raw=v[p];p+=1;let id=Int(raw);if raw!=Float64(id) or id<0 or id>=groups:return -1;ids[e]=Int64(id);seen[id]=1
        for j in range(size):let x=v[p];p+=1;if x < -10.0 or x>10.0:return -1;params[e*16+j]=x
        for j in range(size):let x=v[p];p+=1;if x < -0.01 or x>0.01:return -1;grads[e*16+j]=x
    for i in range(groups):if seen[i]==0:return -1
    let total=2*groups*size;if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(total):return -2
    var velocity=InlineArray[Float64,32](fill=0.0);var last=InlineArray[Float64,32](fill=0.0)
    for e in range(calls):
        let id=Int(ids[e]);var eg=InlineArray[Float64,16](fill=0.0)
        for j in range(size):eg[j]=grads[e*16+j]
        let orth=mu_orth(eg,rows,cols,steps)
        for j in range(size):let ix=id*size+j;velocity[ix]=momentum*velocity[ix]+orth[(j//cols)*4+j%cols];last[ix]=params[e*16+j]-rate*velocity[ix]
    for i in range(groups*size):o[i]=last[i];o[groups*size+i]=velocity[i]
    return Int64(total)
