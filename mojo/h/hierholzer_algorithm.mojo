from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn hza_word(inout h:UInt64,v:Int64):
    let u=bitcast[UInt64](v)
    for b in range(8):h=(h^((u>>UInt(8*b))&255))*1099511628211
@export("hierholzer_algorithm")
fn hierholzer_algorithm(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>514:return -1
    let nv=a[0];let me=a[1]
    if nv<0 or nv>8 or me<0 or me>256 or n!=c_size_t(2+2*me):return -1
    let v=Int(nv);let m=Int(me);var to=InlineArray[Int,4096](fill=0);var eid=InlineArray[Int,4096](fill=0);var deg=InlineArray[Int,8](fill=0);var eu=InlineArray[Int,256](fill=0);var ev=InlineArray[Int,256](fill=0)
    for e in range(m):
        let x=a[2+2*e];let y=a[3+2*e]
        if x<0 or y<0 or x>=nv or y>=nv:return -1
        eu[e]=Int(x);ev[e]=Int(y);to[Int(x)*512+deg[Int(x)]]=Int(y);eid[Int(x)*512+deg[Int(x)]]=e;deg[Int(x)]+=1;to[Int(y)*512+deg[Int(y)]]=Int(x);eid[Int(y)*512+deg[Int(y)]]=e;deg[Int(y)]+=1
    var circuit=1;var start=-1
    for i in range(v):if deg[i]%2!=0:circuit=0
    for i in range(v):if start<0 and deg[i]>0:start=i
    if circuit==1 and start>=0:
        var seen=InlineArray[Bool,8](fill=false);var st=InlineArray[Int,8](fill=0);var top=1;st[0]=start;seen[start]=true
        while top>0:
            top-=1;let x=st[top]
            for j in range(deg[x]):let y=to[x*512+j];if not seen[y]:seen[y]=true;st[top]=y;top+=1
        for i in range(v):if deg[i]>0 and not seen[i]:circuit=0
    var route=InlineArray[Int,257](fill=0);var rn=0
    if circuit==1:
        if start<0:
            if v>0:route[0]=0;rn=1
        else:
            var used=InlineArray[Bool,256](fill=false);var cursor=InlineArray[Int,8](fill=0);var path=InlineArray[Int,257](fill=0);var sp=1;path[0]=start
            while sp>0:
                let x=path[sp-1];var j=cursor[x]
                while j<deg[x] and used[eid[x*512+j]]:j+=1
                cursor[x]=j
                if j<deg[x]:
                    let e=eid[x*512+j];used[e]=true;cursor[x]=j+1;path[sp]=to[x*512+j];sp+=1
                else:sp-=1;route[rn]=path[sp];rn+=1
            for i in range(rn//2):let t=route[i];route[i]=route[rn-1-i];route[rn-1-i]=t
    var h:UInt64=14695981039346656037;hza_word(h,Int64(circuit));hza_word(h,Int64(rn))
    for i in range(rn):hza_word(h,Int64(route[i]))
    return Int64(h&0x7fffffffffffffff)
