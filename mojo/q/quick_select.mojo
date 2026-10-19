from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn qs_median(a:Int64,b:Int64,c:Int64)->Int64:
    if a<=b:
        if b<=c:return b
        if a<=c:return c
        return a
    if b>=c:return b
    if a>=c:return c
    return a
@export("quick_select")
fn quick_select(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1024:return -1
    var v=InlineArray[Int64,1024]()
    for i in range(Int(n)):v[i]=a[i]
    let target=Int(n)/2;var lo=0;var hi=Int(n)
    while True:
        let pivot=qs_median(v[lo],v[lo+(hi-lo)/2],v[hi-1]);var lt=lo;var i=lo;var gt=hi
        while i<gt:
            if v[i]<pivot:let t=v[lt];v[lt]=v[i];v[i]=t;lt+=1;i+=1
            elif v[i]>pivot:gt-=1;let t=v[i];v[i]=v[gt];v[gt]=t
            else:i+=1
        if target<lt:hi=lt
        elif target>=gt:lo=gt
        else:return pivot
