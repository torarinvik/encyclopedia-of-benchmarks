from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn hldm_store(o:UnsafePointer[UInt8,MutAnyOrigin],i:Int,v:Int64):
    let u=bitcast[UInt64](v)
    for b in range(8):o[i*8+b]=UInt8((u>>UInt(8*b))&255)
@export("heavy_light_decomposition_metadata")
fn heavy_light_decomposition_metadata(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let v=a[0];let e=a[1]
    if v<1 or v>128 or e!=v-1 or n!=c_size_t(2+2*e):return -1
    let count=Int(v);var adj=InlineArray[Int,16384](fill=0);var deg=InlineArray[Int,128](fill=0);var seen=InlineArray[Bool,128](fill=false)
    for i in range(Int(e)):
        let x=a[2+2*i];let y=a[3+2*i]
        if x<0 or y<0 or x>=v or y>=v or x==y:return -1
        for j in range(deg[Int(x)]):if adj[Int(x)*128+j]==Int(y):return -1
        adj[Int(x)*128+deg[Int(x)]]=Int(y);deg[Int(x)]+=1
        adj[Int(y)*128+deg[Int(y)]]=Int(x);deg[Int(y)]+=1
    var par=InlineArray[Int,128](fill=-2);var depth=InlineArray[Int,128](fill=0);var order=InlineArray[Int,128](fill=0);var top=0;var used=1;par[0]= -1;order[0]=0
    while top<used:
        let x=order[top];top+=1
        for j in range(deg[x]):
            let y=adj[x*128+j]
            if y==par[x]:continue
            if par[y]!= -2:return -1
            par[y]=x;depth[y]=depth[x]+1;order[used]=y;used+=1
    if used!=count:return -1
    var sub=InlineArray[Int,128](fill=1);var heavy=InlineArray[Int,128](fill=-1)
    for oi in range(count-1):
        let x=order[count-1-oi];var best=0
        for j in range(deg[x]):
            let y=adj[x*128+j]
            if par[y]==x:
                sub[x]+=sub[y]
                if sub[y]>best:best=sub[y];heavy[x]=y
    var pos=InlineArray[Int,128](fill=0);var head=InlineArray[Int,128](fill=0);var sv=InlineArray[Int,256](fill=0);var sh=InlineArray[Int,256](fill=0);var sp=1;sv[0]=0;sh[0]=0;var nextpos=0
    while sp>0:
        sp-=1;let x=sv[sp];let h=sh[sp];pos[x]=nextpos;nextpos+=1;head[x]=h
        var children=InlineArray[Int,128](fill=0);var cn=0
        for j in range(deg[x]):let y=adj[x*128+j];if par[y]==x and y!=heavy[x]:children[cn]=y;cn+=1
        for ci in range(cn):let y=children[cn-1-ci];sv[sp]=y;sh[sp]=y;sp+=1
        if heavy[x]>=0:sv[sp]=heavy[x];sh[sp]=h;sp+=1
    let bytes=(1+3*count)*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    hldm_store(o,0,v)
    for i in range(count):hldm_store(o,1+3*i,Int64(pos[i]));hldm_store(o,2+3*i,Int64(head[i]));hldm_store(o,3+3*i,Int64(heavy[i]))
    return Int64(bytes)
