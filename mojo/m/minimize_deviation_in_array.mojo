from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn mda_push(mut h:InlineArray[Int64,64],mut size:Int,x:Int64):
    var i=size;size+=1
    while i>0 and h[(i-1)//2]<x:h[i]=h[(i-1)//2];i=(i-1)//2
    h[i]=x
fn mda_pop(mut h:InlineArray[Int64,64],mut size:Int)->Int64:
    let res=h[0];size-=1;let last=h[size]
    if size>0:
        var i=0
        while i*2+1<size:
            var c=i*2+1
            if c+1<size and h[c+1]>h[c]:c+=1
            if h[c]<=last:break
            h[i]=h[c];i=c
        h[i]=last
    return res
@export("minimize_deviation_in_array")
fn minimize_deviation_in_array(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65 or v[0]<1 or v[0]>64 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var heap=InlineArray[Int64,64](fill=0);var size=0;var low=9223372036854775807;var high:Int64=0
    for i in range(count):
        let x=v[i+1]
        if x<1 or x>1000000:return -1
        let y=if x%2==1:x*2 else:x;mda_push(mut heap,mut size,y)
        if y<low:low=y
        if y>high:high=y
    var best=high-low
    while heap[0]%2==0:
        high=mda_pop(mut heap,mut size)/2
        if high<low:low=high
        mda_push(mut heap,mut size,high)
        if heap[0]-low<best:best=heap[0]-low
    return best
