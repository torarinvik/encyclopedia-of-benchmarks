from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn hep_store(o:UnsafePointer[UInt8,MutAnyOrigin],i:Int,v:Int64):
    let u=bitcast[UInt64](v)
    for b in range(8):o[i*8+b]=UInt8((u>>UInt(8*b))&255)
@export("hierholzer_eulerian_path")
fn hierholzer_eulerian_path(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>98:return -1
    let nv=a[0];let me=a[1]
    if nv<0 or nv>16 or me<0 or me>48 or n!=c_size_t(2+2*me):return -1
    let v=Int(nv);let m=Int(me);var dst=InlineArray[Int,768](fill=0);var deg=InlineArray[Int,16](fill=0);var indeg=InlineArray[Int,16](fill=0);var und=InlineArray[Bool,256](fill=false)
    for i in range(m):
        let x=a[2+2*i];let y=a[3+2*i]
        if x<0 or y<0 or x>=nv or y>=nv:return -1
        dst[Int(x)*48+deg[Int(x)]]=Int(y);deg[Int(x)]+=1;indeg[Int(y)]+=1;und[Int(x)*16+Int(y)]=true;und[Int(y)*16+Int(x)]=true
    var path=InlineArray[Int,49](fill=0);var plen=0
    if v==0:plen=0
    elif m==0:path[0]=0;plen=1
    else:
        var start=-1;var plus=0;var minus=0;var valid=true
        for i in range(v):
            let d=deg[i]-indeg[i]
            if d==1:start=i;plus+=1
            elif d== -1:minus+=1
            elif d!=0:valid=false
        if not ((plus==1 and minus==1) or (plus==0 and minus==0)):valid=false
        if valid and start<0:
            for i in range(v):if deg[i]>0 and start<0:start=i
        var seen=InlineArray[Bool,16](fill=false);var stack=InlineArray[Int,16](fill=0);var top=0
        if valid:stack[0]=start;top=1;seen[start]=true
        while top>0:
            top-=1;let x=stack[top]
            for y in range(v):if und[x*16+y] and not seen[y]:seen[y]=true;stack[top]=y;top+=1
        for i in range(v):if (deg[i]+indeg[i])>0 and not seen[i]:valid=false
        if valid:
            var used=InlineArray[Bool,48](fill=false);var cursor=InlineArray[Int,16](fill=0);var vs=InlineArray[Int,49](fill=0);var rs=InlineArray[Int,49](fill=0);var sp=1;var rn=0;vs[0]=start
            while sp>0:
                let x=vs[sp-1];var ei=cursor[x]
                while ei<deg[x] and used[x*48+ei]:ei+=1
                cursor[x]=ei
                if ei<deg[x]:
                    used[x*48+ei]=true;cursor[x]=ei+1;vs[sp]=dst[x*48+ei];sp+=1
                else:sp-=1;rs[rn]=vs[sp];rn+=1
            if rn==m+1:
                plen=rn
                for i in range(rn):path[i]=rs[rn-1-i]
    let bytes=8*(plen+1)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    hep_store(o,0,Int64(plen));for i in range(plen):hep_store(o,i+1,Int64(path[i]))
    return Int64(bytes)
