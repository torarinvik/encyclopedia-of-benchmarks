from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime PMAX=8
comptime CMAX=512
struct Path:
    var length: Int
    var nodes: InlineArray[Int,8]
    var cost: Int64
fn path_less(a:Path,b:Path)->Bool:
    if a.cost!=b.cost:return a.cost<b.cost
    for i in range(min(a.length,b.length)):
        if a.nodes[i]!=b.nodes[i]:return a.nodes[i]<b.nodes[i]
    return a.length<b.length
fn path_same(a:Path,b:Path)->Bool:
    if a.length!=b.length:return False
    for i in range(a.length):
        if a.nodes[i]!=b.nodes[i]:return False
    return True
fn same_prefix(a:Path,b:Path,length:Int)->Bool:
    if a.length<length or b.length<length:return False
    for i in range(length):
        if a.nodes[i]!=b.nodes[i]:return False
    return True
fn path_contains(path:Path,node:Int)->Bool:
    for i in range(path.length):
        if path.nodes[i]==node:return True
    return False
fn shortest_spur(n:Int,src:Int,dst:Int,w:InlineArray[Int64,64],banv:InlineArray[UInt8,8],bane:InlineArray[UInt8,64])->(Bool,Path):
    var start_nodes=InlineArray[Int,8](fill=0);start_nodes[0]=src
    var queue=InlineArray[Path,8192](fill=Path(0,InlineArray[Int,8](fill=0),0))
    var queued=1;queue[0]=Path(1,start_nodes,0)
    while queued>0:
        var best=0
        for i in range(1,queued):
            if path_less(queue[i],queue[best]):best=i
        let current=queue[best]
        queue[best]=queue[queued-1];queued-=1
        let u=current.nodes[current.length-1]
        if u==dst:return (True,current)
        for to in range(n):
            if w[u*8+to]<0 or bane[u*8+to]!=0 or banv[to]!=0 or path_contains(current,to):continue
            var next_nodes=current.nodes;next_nodes[current.length]=to
            let next_path=Path(current.length+1,next_nodes,current.cost+w[u*8+to])
            if queued<8192:queue[queued]=next_path;queued+=1
    return (False,Path(0,InlineArray[Int,8](fill=0),0))
@export("yens_kshortest_paths")
fn yens_kshortest_paths(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>68:return -1
    let nv=v[0];let kval=v[1];let src=v[2];let dst=v[3]
    if nv<1 or nv>8 or kval<1 or kval>8 or src<0 or src>=nv or dst<0 or dst>=nv or n!=c_size_t(4+nv*nv):return -1
    var w=InlineArray[Int64,64](fill= -1)
    for i in range(Int(nv*nv)):
        let x=v[4+i]
        if x < -1 or x>1000:return -1
        w[i]=x
    var accepted=InlineArray[Path,8](fill=Path(0,InlineArray[Int,8](fill=0),0));var ac=0
    var banv=InlineArray[UInt8,8](fill=0);var bane=InlineArray[UInt8,64](fill=0)
    let (ok,first)=shortest_spur(Int(nv),Int(src),Int(dst),w,banv,bane)
    if ok:accepted[0]=first;ac=1
    var candidates=InlineArray[Path,512](fill=Path(0,InlineArray[Int,8](fill=0),0));var cc=0
    while ac>0 and ac<Int(kval):
        let last=accepted[ac-1]
        for spur in range(last.length-1):
            var root=Path(spur+1,InlineArray[Int,8](fill=0),0)
            for i in range(spur+1):root.nodes[i]=last.nodes[i]
            for i in range(spur):root.cost+=w[last.nodes[i]*8+last.nodes[i+1]]
            var blocked=InlineArray[UInt8,8](fill=0)
            for i in range(spur):blocked[root.nodes[i]]=1
            var removed=InlineArray[UInt8,64](fill=0)
            for p in range(ac):
                let prior=accepted[p]
                if prior.length>spur+1 and same_prefix(prior,root,spur+1):removed[prior.nodes[spur]*8+prior.nodes[spur+1]]=1
            let (spur_ok,tail)=shortest_spur(Int(nv),root.nodes[spur],Int(dst),w,blocked,removed)
            if not spur_ok:continue
            var combined=Path(spur+tail.length,InlineArray[Int,8](fill=0),root.cost+tail.cost)
            for i in range(spur):combined.nodes[i]=root.nodes[i]
            for i in range(tail.length):combined.nodes[spur+i]=tail.nodes[i]
            var duplicate=False
            for i in range(ac):if path_same(accepted[i],combined):duplicate=True
            for i in range(cc):if path_same(candidates[i],combined):duplicate=True
            if not duplicate and cc<CMAX:candidates[cc]=combined;cc+=1
        if cc==0:break
        var bestidx=0
        for i in range(1,cc):if path_less(candidates[i],candidates[bestidx]):bestidx=i
        accepted[ac]=candidates[bestidx];ac+=1
        candidates[bestidx]=candidates[cc-1];cc-=1
    var staged=InlineArray[Int64,81](fill=0);staged[0]=Int64(ac);var used=1
    for p in range(ac):
        staged[used]=Int64(accepted[p].length);used+=1
        for i in range(accepted[p].length):staged[used]=Int64(accepted[p].nodes[i]);used+=1
        staged[used]=accepted[p].cost;used+=1
    let bytes=used*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(used):
        for b in range(8):o[i*8+b]=UInt8((staged[i]>>(8*b))&255)
    return Int64(bytes)
