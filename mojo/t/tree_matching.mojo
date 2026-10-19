from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("tree_matching")
fn tree_matching(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>191 or a[0]<1 or a[0]>64:return -1
    let count=Int(a[0]);let root=a[1]
    if n!=c_size_t(2+3*(count-1)) or root<0 or root>=count:return -1
    var adj=InlineArray[Bool,4096]();var wt=InlineArray[Int64,4096]()
    for e in range(count-1):
        let u=a[2+3*e];let v=a[3+3*e];let w=a[4+3*e]
        if u<0 or u>=count or v<0 or v>=count or u==v or w<0 or w>1000:return -1
        let ix=Int(u)*64+Int(v);if adj[ix]:return -1
        adj[ix]=True;adj[Int(v)*64+Int(u)]=True;wt[ix]=w;wt[Int(v)*64+Int(u)]=w
    var parent=InlineArray[Int,64]();var order=InlineArray[Int,64]();var stack=InlineArray[Int,64]();var seen=InlineArray[Bool,64]();var top=0;var size=0
    stack[0]=Int(root);top=1;seen[Int(root)]=True;parent[Int(root)]= -1
    while top>0:
        top-=1;let u=stack[top];order[size]=u;size+=1
        for v in range(count):
            if adj[u*64+v] and not seen[v]:seen[v]=True;parent[v]=u;stack[top]=v;top+=1
    if size!=count:return -1
    var no=InlineArray[Int64,64]();var yes=InlineArray[Int64,64]()
    for rev in range(count):
        let u=order[count-1-rev];var base:Int64=0
        for v in range(count):
            if parent[v]==u:base+=max(no[v],yes[v])
        no[u]=base;yes[u]=0
        for v in range(count):
            if parent[v]==u:
                let childbest=max(no[v],yes[v]);let candidate=base-childbest+no[v]+wt[u*64+v]
                if candidate>yes[u]:yes[u]=candidate
    return max(no[Int(root)],yes[Int(root)])
