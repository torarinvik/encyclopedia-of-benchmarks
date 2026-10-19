from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("edmonds")
fn edmonds(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>39:return -1
    var n=Int(input[0]);var root=Int(input[1]);let m=Int(input[2])
    if n<1 or n>5 or root<0 or root>=n or m<0 or m>12 or length!=c_size_t(3+3*m):return -1
    var us=InlineArray[Int64,12](fill=0);var vs=InlineArray[Int64,12](fill=0);var ws=InlineArray[Int64,12](fill=0)
    for i in range(m):
        let u=input[3+3*i];let v=input[4+3*i];let w=input[5+3*i]
        if u<0 or u>=n or v<0 or v>=n or w<0 or w>100:return -1
        us[i]=u;vs[i]=v;ws[i]=w
    var answer:Int64=0
    while True:
        var incoming=InlineArray[Int64,5](fill=1000000000);var previous=InlineArray[Int64,5](fill= -1)
        for i in range(n):
            if i==root:incoming[i]=0
        for i in range(m):
            let u=Int(us[i]);let v=Int(vs[i])
            if u!=v and v!=root and ws[i]<incoming[v]:incoming[v]=ws[i];previous[v]=us[i]
        for i in range(n):if incoming[i]==1000000000:return -1
        var ids=InlineArray[Int64,5](fill= -1);var visited=InlineArray[Int64,5](fill= -1);var cycles=0
        for i in range(n):
            answer+=incoming[i];var v=i
            while visited[v]!=i and ids[v]== -1 and v!=root:visited[v]=i;v=Int(previous[v])
            if v!=root and ids[v]== -1:
                var u=Int(previous[v])
                while u!=v:ids[u]=cycles;u=Int(previous[u])
                ids[v]=cycles;cycles+=1
        if cycles==0:return answer
        var nextid=cycles
        for i in range(n):if ids[i]== -1:ids[i]=nextid;nextid+=1
        for i in range(m):
            let u=Int(us[i]);let v=Int(vs[i]);let old=ws[i]
            let nu=ids[u];let nv=ids[v]
            if nu!=nv:ws[i]=old-incoming[v]
            us[i]=nu;vs[i]=nv
        root=Int(ids[root]);n=nextid
