from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn sr_less(heap:UnsafePointer[Int32,MutAnyOrigin],pos:UnsafePointer[Int32,MutAnyOrigin],starts:UnsafePointer[Int32,MutAnyOrigin],a:UnsafePointer[Int64,ImmutAnyOrigin],x:Int,y:Int)->Bool:
    let lx=Int(heap[x]);let ly=Int(heap[y]);let vx=a[starts[lx]+pos[lx]];let vy=a[starts[ly]+pos[ly]]
    return vx<vy or (vx==vy and lx<ly)
@export("smallest_range")
fn smallest_range(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>273:return -1
    let lists=a[0];if lists<1 or lists>16:return -1
    var starts=InlineArray[Int32,16]();var lens=InlineArray[Int32,16]();var pos=InlineArray[Int32,16]();var heap=InlineArray[Int32,16]()
    var p=1;var total=0;var heapn=0;var curmax:Int64= -1000000001
    for l in range(Int(lists)):
        if p>=Int(n):return -1
        let k=a[p];p+=1;if k<1 or k>16 or total+Int(k)>256 or p+Int(k)>Int(n):return -1
        starts[l]=Int32(p);lens[l]=Int32(k);total+=Int(k)
        for j in range(Int(k)):
            let v=a[p+j];if v< -1000000000 or v>1000000000 or (j>0 and v<a[p+j-1]):return -1
        if a[p]>curmax:curmax=a[p]
        heap[heapn]=Int32(l);var child=heapn;heapn+=1
        while child>0:
            let par=(child-1)/2;if not sr_less(heap.unsafe_ptr(),pos.unsafe_ptr(),starts.unsafe_ptr(),a,child,par):break
            let t=heap[child];heap[child]=heap[par];heap[par]=t;child=par
        p+=Int(k)
    if p!=Int(n):return -1
    var bestlo:Int64=0;var besthi:Int64=0;var bestwidth:Int64=9223372036854775807
    while true:
        let l=Int(heap[0]);let lo=a[starts[l]+pos[l]];let width=curmax-lo
        if width<bestwidth:bestwidth=width;bestlo=lo;besthi=curmax
        pos[l]+=1;if pos[l]>=lens[l]:break
        let v=a[starts[l]+pos[l]];if v>curmax:curmax=v
        var root=0
        while true:
            let left=root*2+1;if left>=heapn:break
            var ch=left;if left+1<heapn and sr_less(heap.unsafe_ptr(),pos.unsafe_ptr(),starts.unsafe_ptr(),a,left+1,left):ch=left+1
            if not sr_less(heap.unsafe_ptr(),pos.unsafe_ptr(),starts.unsafe_ptr(),a,ch,root):break
            let t=heap[root];heap[root]=heap[ch];heap[ch]=t;root=ch
    return (bestlo+1000000000)*2000000001+besthi+1000000000
