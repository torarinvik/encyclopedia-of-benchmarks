from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("problem107")
fn problem107(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>781:return -1
    let raw=v[0]
    if raw<1 or raw>40 or n!=c_size_t(1+raw*(raw-1)//2):return -1
    let count=Int(raw);var weights=InlineArray[Int64,1600](fill= -1);var total=Int64(0);var pos=1
    for r in range(1,count):for c in range(r):
        let w=v[pos];pos+=1
        if w< -1 or w>999:return -1
        weights[r*40+c]=w;weights[c*40+r]=w
        if w>=0:total+=w
    var used=InlineArray[Bool,40](fill=False);var best=InlineArray[Int64,40](fill=1000);best[0]=0;var tree=Int64(0)
    for _ in range(count):
        var node= -1;var value=Int64(1000)
        for i in range(count):if not used[i] and best[i]<value:value=best[i];node=i
        if node<0:return -1
        used[node]=True;tree+=value
        for j in range(count):if not used[j] and weights[node*40+j]>=0 and weights[node*40+j]<best[j]:best[j]=weights[node*40+j]
    return total-tree
