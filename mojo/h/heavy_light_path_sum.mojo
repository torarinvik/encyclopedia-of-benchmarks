from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn hlps_store(o:UnsafePointer[UInt8,MutAnyOrigin],i:Int,v:Int64):
    let u=bitcast[UInt64](v)
    for b in range(8):o[i*8+b]=UInt8((u>>UInt(8*b))&255)
fn hlps_query(tree:InlineArray[Int64,256],left:Int,right:Int)->Int64:
    var l=left+128;var r=right+128;var answer:Int64=0
    while l<=r:
        if l%2==1:answer+=tree[l];l+=1
        if r%2==0:answer+=tree[r];r-=1
        l//=2;r//=2
    return answer
@export("heavy_light_path_sum")
fn heavy_light_path_sum(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2:return -1
    let nv=a[0];let qv=a[1]
    if nv<1 or nv>64 or qv<0 or qv>128:return -1
    let count=Int(nv);let q=Int(qv);let edgepos=2+count;let op_pos=edgepos+2*(count-1)
    if n!=c_size_t(op_pos+3*q):return -1
    var vals=InlineArray[Int64,64](fill=0)
    for i in range(count):vals[i]=a[2+i];if vals[i]< -2147483648 or vals[i]>2147483647:return -1
    var adj=InlineArray[Int,4096](fill=0);var deg=InlineArray[Int,64](fill=0)
    for i in range(count-1):
        let x=a[edgepos+2*i];let y=a[edgepos+2*i+1]
        if x<0 or y<0 or x>=nv or y>=nv or x==y:return -1
        for j in range(deg[Int(x)]):if adj[Int(x)*64+j]==Int(y):return -1
        adj[Int(x)*64+deg[Int(x)]]=Int(y);deg[Int(x)]+=1;adj[Int(y)*64+deg[Int(y)]]=Int(x);deg[Int(y)]+=1
    var par=InlineArray[Int,64](fill=-2);var depth=InlineArray[Int,64](fill=0);var order=InlineArray[Int,64](fill=0);par[0]= -1;order[0]=0;var used=1;var ix=0
    while ix<used:
        let x=order[ix];ix+=1
        for j in range(deg[x]):
            let y=adj[x*64+j]
            if y==par[x]:continue
            if par[y]!= -2:return -1
            par[y]=x;depth[y]=depth[x]+1;order[used]=y;used+=1
    if used!=count:return -1
    var sub=InlineArray[Int,64](fill=1);var heavy=InlineArray[Int,64](fill=-1)
    for oi in range(count-1):
        let x=order[count-1-oi];var best=0
        for j in range(deg[x]):
            let y=adj[x*64+j]
            if par[y]==x:
                sub[x]+=sub[y]
                if sub[y]>best:best=sub[y];heavy[x]=y
    var head=InlineArray[Int,64](fill=0);var pos=InlineArray[Int,64](fill=0);var sv=InlineArray[Int,128](fill=0);var sh=InlineArray[Int,128](fill=0);var sp=1;var next=0;sv[0]=0;sh[0]=0
    while sp>0:
        sp-=1;let x=sv[sp];let h=sh[sp];head[x]=h;pos[x]=next;next+=1
        var children=InlineArray[Int,64](fill=0);var cn=0
        for j in range(deg[x]):let y=adj[x*64+j];if par[y]==x and y!=heavy[x]:children[cn]=y;cn+=1
        for ci in range(cn):let y=children[cn-1-ci];sv[sp]=y;sh[sp]=y;sp+=1
        if heavy[x]>=0:sv[sp]=heavy[x];sh[sp]=h;sp+=1
    var seg=InlineArray[Int64,256](fill=0)
    for i in range(count):seg[128+pos[i]]=vals[i]
    for i in range(127,0,-1):seg[i]=seg[2*i]+seg[2*i+1]
    var stage=InlineArray[Int64,128](fill=0);var nq=0
    for i in range(q):
        let op=a[op_pos+3*i];let x0=a[op_pos+3*i+1];let z=a[op_pos+3*i+2]
        if op<0 or op>1 or x0<0 or x0>=nv:return -1
        if op==0:
            if z< -2147483648 or z>2147483647:return -1
            let x=Int(x0);vals[x]=z;var p=128+pos[x];seg[p]=z;p//=2
            while p>0:seg[p]=seg[2*p]+seg[2*p+1];p//=2
        else:
            if z<0 or z>=nv:return -1
            var x=Int(x0);var y=Int(z);var answer:Int64=0
            while head[x]!=head[y]:
                if depth[head[x]]>=depth[head[y]]:answer+=hlps_query(seg,pos[head[x]],pos[x]);x=par[head[x]]
                else:answer+=hlps_query(seg,pos[head[y]],pos[y]);y=par[head[y]]
            answer+=hlps_query(seg,min(pos[x],pos[y]),max(pos[x],pos[y]));stage[nq]=answer;nq+=1
    let bytes=nq*8
    if cap<c_size_t(bytes) or (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    for i in range(nq):hlps_store(o,i,stage[i])
    return Int64(bytes)
