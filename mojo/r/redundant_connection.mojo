from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn red_find(mut p:InlineArray[Int64,1001],x:Int)->Int:
    var root=x
    while p[root]!=Int64(root):root=Int(p[root])
    var q=x
    while p[q]!=Int64(q):let next=Int(p[q]);p[q]=Int64(root);q=next
    return root
@export("redundant_connection")
fn redundant_connection(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>2000 or (n&1)!=0:return -1
    let edges=Int(n)//2
    for i in range(Int(n)):if v[i]<1 or v[i]>Int64(edges):return -1
    for i in range(edges):if v[2*i]==v[2*i+1]:return -1
    var parent=InlineArray[Int64,1001](fill=0)
    for i in range(edges+1):parent[i]=Int64(i)
    var left:Int64=0;var right:Int64=0;var redundant=0
    for i in range(edges):
        let a=Int(v[2*i]);let b=Int(v[2*i+1]);let ra=red_find(parent,a);let rb=red_find(parent,b)
        if ra==rb:left=v[2*i];right=v[2*i+1];redundant+=1
        else:parent[ra]=Int64(rb)
    if redundant!=1:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    for e in range(2):
        let x=UInt32(if e==0:left else:right)
        for b in range(4):o[e*4+b]=UInt8((x>>(8*b))&255)
    return 2
