# Independent bounded ParGeo bichromatic KD-tree profile; see LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@fieldwise_init
struct PargeoTree:
    var x: InlineArray[Int64,8]
    var y: InlineArray[Int64,8]
    var order: InlineArray[Int,8]
    var left: InlineArray[Int,15]
    var right: InlineArray[Int,15]
    var start: InlineArray[Int,15]
    var count: InlineArray[Int,15]
    var minx: InlineArray[Int64,15]
    var maxx: InlineArray[Int64,15]
    var miny: InlineArray[Int64,15]
    var maxy: InlineArray[Int64,15]
    var used: Int

fn pargeo_build(mut tree: PargeoTree, start: Int, count: Int) -> Int:
    let node=tree.used; tree.used+=1
    tree.left[node] = -1; tree.right[node] = -1
    tree.start[node]=start; tree.count[node]=count
    let first=tree.order[start]
    tree.minx[node]=tree.x[first]; tree.maxx[node]=tree.x[first]
    tree.miny[node]=tree.y[first]; tree.maxy[node]=tree.y[first]
    for i in range(1,count):
        let p=tree.order[start+i]
        tree.minx[node]=min(tree.minx[node],tree.x[p]); tree.maxx[node]=max(tree.maxx[node],tree.x[p])
        tree.miny[node]=min(tree.miny[node],tree.y[p]); tree.maxy[node]=max(tree.maxy[node],tree.y[p])
    if count<=2: return node
    let axis_x=tree.maxx[node]-tree.minx[node]>tree.maxy[node]-tree.miny[node]
    let midpoint=tree.minx[node]+tree.maxx[node] if axis_x else tree.miny[node]+tree.maxy[node]
    var left_count=0
    for i in range(count):
        let p=tree.order[start+i]
        let coordinate=tree.x[p] if axis_x else tree.y[p]
        if 2*coordinate<midpoint: left_count+=1
    var scratch=InlineArray[Int,8](fill=0)
    if left_count==0 or left_count==count:
        left_count=(count+1)//2
        for i in range(count): scratch[i]=tree.order[start+i]
    else:
        var l=0; var r=left_count
        for i in range(count):
            let p=tree.order[start+i]
            let coordinate=tree.x[p] if axis_x else tree.y[p]
            if 2*coordinate<midpoint: scratch[l]=p; l+=1
            else: scratch[r]=p; r+=1
    for i in range(count): tree.order[start+i]=scratch[i]
    let left=pargeo_build(tree,start,left_count)
    let right=pargeo_build(tree,start+left_count,count-left_count)
    tree.left[node]=left; tree.right[node]=right; tree.count[node]=0
    return node

fn pargeo_box(a: PargeoTree, ai: Int, b: PargeoTree, bi: Int) -> Int64:
    var dx=Int64(0); var dy=Int64(0)
    if a.maxx[ai]<b.minx[bi]: dx=b.minx[bi]-a.maxx[ai]
    elif b.maxx[bi]<a.minx[ai]: dx=a.minx[ai]-b.maxx[bi]
    if a.maxy[ai]<b.miny[bi]: dy=b.miny[bi]-a.maxy[ai]
    elif b.maxy[bi]<a.miny[ai]: dy=a.miny[ai]-b.maxy[bi]
    return dx*dx+dy*dy

fn pargeo_search(a: PargeoTree, ai: Int, b: PargeoTree, bi: Int, best: Int64) -> Int64:
    if pargeo_box(a,ai,b,bi)>best: return best
    var answer=best
    if a.left[ai]<0 and b.left[bi]<0:
        for i in range(a.count[ai]):
            let p=a.order[a.start[ai]+i]
            for j in range(b.count[bi]):
                let q=b.order[b.start[bi]+j]
                let dx=a.x[p]-b.x[q]; let dy=a.y[p]-b.y[q]
                answer=min(answer,dx*dx+dy*dy)
        return answer
    var asides=InlineArray[Int,4](fill=0); var bsides=InlineArray[Int,4](fill=0)
    var bounds=InlineArray[Int64,4](fill=0); var count=0
    if a.left[ai]<0:
        asides[0]=ai; bsides[0]=b.left[bi]; asides[1]=ai; bsides[1]=b.right[bi]; count=2
    elif b.left[bi]<0:
        asides[0]=a.left[ai]; bsides[0]=bi; asides[1]=a.right[ai]; bsides[1]=bi; count=2
    else:
        asides[0]=a.left[ai]; bsides[0]=b.left[bi]
        asides[1]=a.left[ai]; bsides[1]=b.right[bi]
        asides[2]=a.right[ai]; bsides[2]=b.left[bi]
        asides[3]=a.right[ai]; bsides[3]=b.right[bi]; count=4
    for i in range(count): bounds[i]=pargeo_box(a,asides[i],b,bsides[i])
    # The one-leaf cases visit the right child first on equal bounds.
    if count==2 and bounds[0]==bounds[1]:
        let x=asides[0]; let y=bsides[0]
        asides[0]=asides[1]; bsides[0]=bsides[1]
        asides[1]=x; bsides[1]=y
    for i in range(1,count):
        let x=asides[i]; let y=bsides[i]; let bound=bounds[i]; var j=i
        while j>0 and bound<bounds[j-1]:
            asides[j]=asides[j-1]; bsides[j]=bsides[j-1]; bounds[j]=bounds[j-1]; j-=1
        asides[j]=x; bsides[j]=y; bounds[j]=bound
    for i in range(count): answer=pargeo_search(a,asides[i],b,bsides[i],answer)
    return answer

fn pargeo_empty() -> PargeoTree:
    return PargeoTree(x=InlineArray[Int64,8](fill=0),y=InlineArray[Int64,8](fill=0),
        order=InlineArray[Int,8](fill=0),left=InlineArray[Int,15](fill=0),right=InlineArray[Int,15](fill=0),
        start=InlineArray[Int,15](fill=0),count=InlineArray[Int,15](fill=0),
        minx=InlineArray[Int64,15](fill=0),maxx=InlineArray[Int64,15](fill=0),
        miny=InlineArray[Int64,15](fill=0),maxy=InlineArray[Int64,15](fill=0),used=0)

@export("pargeo_bichromatic_closest_pair")
fn pargeo_bichromatic_closest_pair(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<10 or length>34: return -1
    if input[0]<2 or input[0]>8 or input[1]<2 or input[1]>8: return -1
    let na=Int(input[0]); let nb=Int(input[1])
    if length!=c_size_t(2+2*(na+nb)): return -1
    for i in range(2,Int(length)):
        if input[i] < -1000000 or input[i]>1000000: return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<8: return -2
    var a=pargeo_empty(); var b=pargeo_empty()
    for i in range(na): a.x[i]=input[2+2*i]; a.y[i]=input[3+2*i]; a.order[i]=i
    for i in range(nb): b.x[i]=input[2+2*na+2*i]; b.y[i]=input[3+2*na+2*i]; b.order[i]=i
    let root_a=pargeo_build(a,0,na); let root_b=pargeo_build(b,0,nb)
    let best=pargeo_search(a,root_a,b,root_b,9223372036854775807)
    let bits=bitcast[UInt64](best)
    for byte in range(8): output[byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return 8
