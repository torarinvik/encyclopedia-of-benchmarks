from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
comptime RT_MAX_OPS=256
comptime RT_MAX_WORD=32
comptime RT_MAX_ROOT=8192
comptime RT_NODES=513
fn rt_prefix_byte(root:InlineArray[UInt8,RT_MAX_ROOT],nodes:InlineArray[UInt8,RT_NODES*RT_MAX_WORD],node:Int,index:Int)->Int:
    if node==0:return Int(root[index])
    return Int(nodes[node*RT_MAX_WORD+index])
fn rt_child_count(children:InlineArray[Int64,RT_NODES*26],node:Int)->Int:
    var count=0
    for c in range(26):if children[node*26+c]!=0:count+=1
    return count
fn rt_only_child(children:InlineArray[Int64,RT_NODES*26],node:Int)->Int:
    for c in range(26):if children[node*26+c]!=0:return Int(children[node*26+c])-1
    return 0
fn rt_merge(mut root:InlineArray[UInt8,RT_MAX_ROOT],mut np:InlineArray[UInt8,RT_NODES*RT_MAX_WORD],mut plen:InlineArray[Int64,RT_NODES],mut kids:InlineArray[Int64,RT_NODES*26],mut leaf:InlineArray[Bool,RT_NODES],dst:Int,src:Int)->Bool:
    let dl=Int(plen[dst]);let sl=Int(plen[src]);let limit=if dst==0:RT_MAX_ROOT else:RT_MAX_WORD
    if dl+sl>limit:return False
    for i in range(sl):
        let b=rt_prefix_byte(root,np,src,i)
        if dst==0:root[dl+i]=UInt8(b)
        else:np[dst*RT_MAX_WORD+dl+i]=UInt8(b)
    plen[dst]=Int64(dl+sl);leaf[dst]=leaf[src]
    for i in range(26):kids[dst*26+i]=kids[src*26+i]
    return True
fn rt_insert(mut root:InlineArray[UInt8,RT_MAX_ROOT],mut np:InlineArray[UInt8,RT_NODES*RT_MAX_WORD],mut plen:InlineArray[Int64,RT_NODES],mut kids:InlineArray[Int64,RT_NODES*26],mut leaf:InlineArray[Bool,RT_NODES],mut nextnode:Int,node:Int,v:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,end:Int)->Bool:
    let remain=end-start
    if remain==0:leaf[node]=True;return True
    if Int(plen[node])==remain and not leaf[node]:
        var j=0
        while j<remain and rt_prefix_byte(root,np,node,j)==Int(v[start+j]):j+=1
        if j==remain:leaf[node]=True;return True
    let letter=Int(v[start])-97;let enc=kids[node*26+letter]
    if enc==0:
        if nextnode>=RT_NODES:return False
        let child=nextnode;nextnode+=1
        for j in range(remain):np[child*RT_MAX_WORD+j]=UInt8(v[start+j])
        plen[child]=Int64(remain);leaf[child]=True;kids[node*26+letter]=Int64(child+1);return True
    let child=Int(enc)-1;let clen=Int(plen[child]);var matched=0
    while matched<clen and matched<remain and rt_prefix_byte(root,np,child,matched)==Int(v[start+matched]):matched+=1
    let remprefix=clen-matched
    if remprefix==0:return rt_insert(root,np,plen,kids,leaf,nextnode,child,v,start+matched,end)
    if nextnode>=RT_NODES:return False
    for j in range(remprefix):
        let b=rt_prefix_byte(root,np,child,matched+j);np[child*RT_MAX_WORD+j]=UInt8(b)
    plen[child]=Int64(remprefix)
    let middle=nextnode;nextnode+=1
    for j in range(matched):np[middle*RT_MAX_WORD+j]=UInt8(v[start+j])
    plen[middle]=Int64(matched)
    let oldletter=Int(np[child*RT_MAX_WORD])-97;kids[middle*26+oldletter]=Int64(child+1);kids[node*26+letter]=Int64(middle+1)
    if start+matched==end:leaf[middle]=True;return True
    return rt_insert(root,np,plen,kids,leaf,nextnode,middle,v,start+matched,end)
fn rt_find(root:InlineArray[UInt8,RT_MAX_ROOT],np:InlineArray[UInt8,RT_NODES*RT_MAX_WORD],plen:InlineArray[Int64,RT_NODES],kids:InlineArray[Int64,RT_NODES*26],leaf:InlineArray[Bool,RT_NODES],node:Int,v:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,end:Int)->Bool:
    if start>=end:return leaf[node]
    let letter=Int(v[start])-97;let enc=kids[node*26+letter];if enc==0:return False
    let child=Int(enc)-1;let clen=Int(plen[child]);var matched=0
    while matched<clen and start+matched<end and rt_prefix_byte(root,np,child,matched)==Int(v[start+matched]):matched+=1
    if matched!=clen:return False
    let next=start+matched
    if next==end:return leaf[child]
    return rt_find(root,np,plen,kids,leaf,child,v,next,end)
fn rt_delete(mut root:InlineArray[UInt8,RT_MAX_ROOT],mut np:InlineArray[UInt8,RT_NODES*RT_MAX_WORD],mut plen:InlineArray[Int64,RT_NODES],mut kids:InlineArray[Int64,RT_NODES*26],mut leaf:InlineArray[Bool,RT_NODES],node:Int,v:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,end:Int)->Int:
    if start>=end:return 0
    let letter=Int(v[start])-97;let enc=kids[node*26+letter];if enc==0:return 0
    let child=Int(enc)-1;let clen=Int(plen[child]);var matched=0
    while matched<clen and start+matched<end and rt_prefix_byte(root,np,child,matched)==Int(v[start+matched]):matched+=1
    if matched!=clen:return 0
    let next=start+matched
    if next<end:return rt_delete(root,np,plen,kids,leaf,child,v,next,end)
    if not leaf[child]:return 0
    let cc=rt_child_count(kids,child)
    if cc==0:
        kids[node*26+letter]=0
        if not leaf[node] and rt_child_count(kids,node)==1:
            let survivor=rt_only_child(kids,node)
            return if rt_merge(root,np,plen,kids,leaf,node,survivor):1 else:-1
    elif cc>1:leaf[child]=False
    else:
        let survivor=rt_only_child(kids,child)
        return if rt_merge(root,np,plen,kids,leaf,child,survivor):1 else:-1
    return 1
@export("radix_tree_benchmark")
fn radix_tree_benchmark(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>8706 or v[0]<0 or v[0]>RT_MAX_OPS:return -1
    let ops=Int(v[0]);var root=InlineArray[UInt8,RT_MAX_ROOT](fill=0);var np=InlineArray[UInt8,RT_NODES*RT_MAX_WORD](fill=0);var plen=InlineArray[Int64,RT_NODES](fill=0);var kids=InlineArray[Int64,RT_NODES*26](fill=0);var leaf=InlineArray[Bool,RT_NODES](fill=False);var nextnode=1;var pos=1;var checksum:Int64=0
    for opi in range(ops):
        if pos+2>Int(n):return -1
        let op=v[pos];let wl=v[pos+1];pos+=2
        if op<0 or op>2 or wl<1 or wl>32 or Int(wl)>Int(n)-pos:return -1
        for j in range(Int(wl)):if v[pos+j]<97 or v[pos+j]>122:return -1
        var observed=0
        if op==0:
            if not rt_insert(root,np,plen,kids,leaf,nextnode,0,v,pos,pos+Int(wl)):return -1
        elif op==1:observed=Int(rt_find(root,np,plen,kids,leaf,0,v,pos,pos+Int(wl)))
        else:
            observed=rt_delete(root,np,plen,kids,leaf,0,v,pos,pos+Int(wl));if observed<0:return -1
        if op!=0:checksum+=Int64(opi+1)*Int64(1+observed)
        pos+=Int(wl)
    if pos!=Int(n):return -1
    return checksum
