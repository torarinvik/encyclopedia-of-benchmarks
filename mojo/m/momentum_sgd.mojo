from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("momentum_sgd")
fn momentum_sgd(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<5 or n>270:return -1
    for i in range(Int(n)):if not is_finite(v[i]):return -1
    let g=Int(v[0]);let width=Int(v[1]);let calls=Int(v[2])
    if v[0]!=Float64(g) or v[1]!=Float64(width) or v[2]!=Float64(calls) or g<1 or g>8 or width<1 or width>16 or calls<1 or calls>8 or g*width>32 or calls<g:return -1
    if Int(n)!=5+calls*(1+2*width) or n>269 or v[3]<1e-6 or v[3]>1.0 or v[4]<0.0 or v[4]>0.99:return -1
    var seen=InlineArray[Int64,8](fill=0);var vel=InlineArray[Float64,32](fill=0.0);var params=InlineArray[Float64,32](fill=0.0);var cursor=5
    for _ in range(calls):
        let raw=v[cursor];cursor+=1;let id=Int(raw)
        if raw!=Float64(id) or id<0 or id>=g:return -1
        seen[id]=1
        for j in range(width):let p=v[cursor];cursor+=1;if p < -1000.0 or p>1000.0:return -1;params[id*width+j]=p
        for j in range(width):
            let grad=v[cursor];cursor+=1;if grad < -1000.0 or grad>1000.0:return -1
            vel[id*width+j]=v[4]*vel[id*width+j]-v[3]*grad;params[id*width+j]+=vel[id*width+j]
    for id in range(g):if seen[id]==0:return -1
    let count=2*g*width
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    for i in range(g*width):out[i]=params[i];out[g*width+i]=vel[i]
    return Int64(count)
