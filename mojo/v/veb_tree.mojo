from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MAXNODES=358
comptime MAXCLUSTERS=16
struct VebNode:
    var universe: UInt16
    var low_bits: UInt8
    var cluster_count: UInt8
    var minimum: Int32
    var maximum: Int32
    var summary: Int32
    var clusters: InlineArray[Int32,16]
    fn __init__(out self, u:UInt16=0, lb:UInt8=0, cc:UInt8=0, mn:Int32= -1, mx:Int32=0, sm:Int32= -1, cl:InlineArray[Int32,16]=InlineArray[Int32,16](fill=0)):
        self.universe=u;self.low_bits=lb;self.cluster_count=cc;self.minimum=mn;self.maximum=mx;self.summary=sm;self.clusters=cl
fn init_veb(nodes:UnsafePointer[VebNode,MutAnyOrigin],next:Int,universe:Int)->(Int,Int):
    let id=next;nodes[id]=VebNode(UInt16(universe))
    if universe>2:
        var exponent=0;var x=universe
        while x>1:exponent+=1;x=x>>1
        let lowbits=exponent/2;let lowsize=1<<lowbits;let clusters=universe/lowsize
        var node=nodes[id];node.low_bits=UInt8(lowbits);node.cluster_count=UInt8(clusters);nodes[id]=node
        let (summary,next1)=init_veb(nodes,id+1,clusters)
        node=nodes[id];node.summary=Int32(summary);nodes[id]=node
        var nextid=next1
        for i in range(clusters):
            let (child,newnext)=init_veb(nodes,nextid,lowsize)
            node=nodes[id];node.clusters[i]=Int32(child);nodes[id]=node;nextid=newnext
        return(id,nextid)
    return(id,id+1)
fn veb_contains(nodes:UnsafePointer[VebNode,ImmutAnyOrigin],id:Int,value:Int)->Bool:
    let node=nodes[id]
    if node.minimum<0:return False
    if Int(node.minimum)==value or Int(node.maximum)==value:return True
    if node.universe==2:return False
    let low_size=1<<Int(node.low_bits);let high=value>>Int(node.low_bits);let low=value&(low_size-1)
    return veb_contains(nodes,Int(node.clusters[high]),low)
fn veb_insert(nodes:UnsafePointer[VebNode,MutAnyOrigin],id:Int,value0:Int):
    if veb_contains(UnsafePointer[VebNode,ImmutAnyOrigin](nodes),id,value0):return
    var value=value0;var node=nodes[id]
    if node.minimum<0:node.minimum=Int32(value);node.maximum=Int32(value);nodes[id]=node;return
    if value<Int(node.minimum):let old=Int(node.minimum);node.minimum=Int32(value);value=old;nodes[id]=node
    node=nodes[id]
    if node.universe>2:
        let lowbits=Int(node.low_bits);let lowsize=1<<lowbits;let high=value>>lowbits;let low=value&(lowsize-1)
        let cluster=Int(node.clusters[high]);let summary=Int(node.summary)
        if nodes[cluster].minimum<0:
            veb_insert(nodes,summary,high)
            var child=nodes[cluster];child.minimum=Int32(low);child.maximum=Int32(low);nodes[cluster]=child
        else:veb_insert(nodes,cluster,low)
    node=nodes[id]
    if value>Int(node.maximum):node.maximum=Int32(value);nodes[id]=node
fn veb_successor(nodes:UnsafePointer[VebNode,ImmutAnyOrigin],id:Int,value:Int)->Int:
    let node=nodes[id]
    if node.minimum<0:return -1
    if value<Int(node.minimum):return Int(node.minimum)
    if node.universe==2:return 1 if value==0 and node.maximum==1 else -1
    let lowbits=Int(node.low_bits);let lowsize=1<<lowbits;let high=value>>lowbits;let low=value&(lowsize-1);let cluster=Int(node.clusters[high])
    if nodes[cluster].minimum>=0 and low<Int(nodes[cluster].maximum):
        let nextlow=veb_successor(nodes,cluster,low)
        if nextlow<0:return -1
        return high*lowsize+nextlow
    let nextcluster=veb_successor(nodes,Int(node.summary),high)
    if nextcluster<0:return -1
    let nextmin=nodes[Int(node.clusters[nextcluster])].minimum
    if nextmin<0:return -1
    return nextcluster*lowsize+Int(nextmin)
fn veb_predecessor(nodes:UnsafePointer[VebNode,ImmutAnyOrigin],id:Int,value:Int)->Int:
    let node=nodes[id]
    if node.minimum<0 or value<=Int(node.minimum):return -1
    if value>Int(node.maximum):return Int(node.maximum)
    if node.universe==2:return 0 if value==1 and node.minimum==0 else -1
    let lowbits=Int(node.low_bits);let lowsize=1<<lowbits;let high=value>>lowbits;let low=value&(lowsize-1);let cluster=Int(node.clusters[high])
    if nodes[cluster].minimum>=0 and low>Int(nodes[cluster].minimum):
        let prevlow=veb_predecessor(nodes,cluster,low)
        if prevlow>=0:return high*lowsize+prevlow
    let prevcluster=veb_predecessor(nodes,Int(node.summary),high)
    if prevcluster<0:return Int(node.minimum)
    let prevmax=nodes[Int(node.clusters[prevcluster])].maximum
    if prevmax<0:return -1
    return prevcluster*lowsize+Int(prevmax)
@export("veb_tree")
fn veb_tree(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>772:return -1
    let requested=v[0];let inserts=v[1];let queries=v[2]
    if requested<2 or requested>256 or inserts<0 or inserts>256 or queries<0 or queries>256 or n!=c_size_t(3+inserts+2*queries):return -1
    for i in range(Int(inserts)):
        if v[3+i]<0 or v[3+i]>=requested:return -1
    for i in range(Int(queries)):
        let op=v[3+Int(inserts)+2*i];let key=v[4+Int(inserts)+2*i]
        if op<0 or op>4 or key<0 or key>=requested:return -1
    let bytes=Int(queries)*4
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var universe=1;while universe<Int(requested):universe*=2
    var nodes=InlineArray[VebNode,358](fill=VebNode())
    let (root,_)=init_veb(nodes.unsafe_ptr(),0,universe)
    for i in range(Int(inserts)):veb_insert(nodes.unsafe_ptr(),root,Int(v[3+i]))
    var staged=InlineArray[UInt8,1024](fill=0)
    for i in range(Int(queries)):
        let at=3+Int(inserts)+2*i;let op=Int(v[at]);let key=Int(v[at+1]);let node=nodes[root]
        var result=0
        if op==0:result=1 if veb_contains(UnsafePointer[VebNode,ImmutAnyOrigin](nodes.unsafe_ptr()),root,key) else 0
        elif op==1:result=veb_successor(UnsafePointer[VebNode,ImmutAnyOrigin](nodes.unsafe_ptr()),root,key)
        elif op==2:result=veb_predecessor(UnsafePointer[VebNode,ImmutAnyOrigin](nodes.unsafe_ptr()),root,key)
        elif op==3:result=Int(node.minimum)
        else:result=0 if node.minimum<0 else Int(node.maximum)
        let raw=UInt32(result) if result>=0 else UInt32(0xffffffff)
        for b in range(4):staged[4*i+b]=UInt8((raw>>(8*b))&255)
    for i in range(bytes):o[i]=staged[i]
    return Int64(bytes)
