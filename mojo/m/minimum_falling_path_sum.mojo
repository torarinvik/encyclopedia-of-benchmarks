from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("minimum_falling_path_sum")
fn minimum_falling_path_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<1 or v[0]>100 or Int(n)!=1+Int(v[0]*v[0]):return -10001
    let dim=Int(v[0]);var cur=InlineArray[Int64,100](fill=0);var nxt=InlineArray[Int64,100](fill=0)
    for c in range(dim):if v[c+1] < -100 or v[c+1]>100:return -10001;cur[c]=v[c+1]
    for r in range(1,dim):
        for c in range(dim):
            let idx=1+r*dim+c;let x=v[idx]
            if x < -100 or x>100:return -10001
            var best=cur[c]
            if c>0 and cur[c-1]<best:best=cur[c-1]
            if c+1<dim and cur[c+1]<best:best=cur[c+1]
            nxt[c]=best+x
        for c in range(dim):cur[c]=nxt[c]
    var best=cur[0]
    for c in range(1,dim):if cur[c]<best:best=cur[c]
    return best
