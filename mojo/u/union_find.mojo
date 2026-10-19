from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn root(parent:InlineArray[Int,256], x0:Int)->Int:
    var p=parent; var x=x0
    while p[x]!=x:x=p[x]
    return x
@export("union_find_benchmark")
fn union_find_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1538:return -1
    let items=v[0];let ops=v[1]
    if items<1 or items>256 or ops<0 or ops>512 or n!=c_size_t(2+3*ops):return -1
    for i in range(Int(ops)):
        let at=2+3*i;let op=v[at];let a=v[at+1];let b=v[at+2]
        if op==0 or op==1:
            if a<0 or a>=items or b<0 or b>=items:return -1
        elif op==2:
            if a!=0 or b!=0:return -1
        else:return -1
    var parent=InlineArray[Int,256](fill=0);var sizes=InlineArray[Int,256](fill=0)
    for i in range(Int(items)):parent[i]=i;sizes[i]=1
    var comps=Int(items);var pairs:Int64=0;var sum:Int64=0
    for i in range(Int(ops)):
        let at=2+3*i;let op=v[at];let a=Int(v[at+1]);let b=Int(v[at+2]);var observed:Int64=0
        var ra=a;while parent[ra]!=ra:parent[ra]=parent[parent[ra]];ra=parent[ra]
        var rb=b;while parent[rb]!=rb:parent[rb]=parent[parent[rb]];rb=parent[rb]
        if op==0:
            if ra!=rb:
                pairs+=Int64(sizes[ra]*sizes[rb])
                if sizes[ra]<sizes[rb]:parent[ra]=rb;sizes[rb]+=sizes[ra]
                else:parent[rb]=ra;sizes[ra]+=sizes[rb]
                comps-=1;observed=1
        elif op==1: observed=1 if ra==rb else 0
        else: observed=Int64(comps)
        sum+=Int64(i+1)*(observed+1000003)
    return sum+pairs
