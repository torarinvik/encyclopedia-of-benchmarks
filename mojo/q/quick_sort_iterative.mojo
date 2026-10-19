from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn qsi_partition(v:UnsafePointer[Int64,MutAnyOrigin],lo:Int,hi:Int)->Int:
    let pivot=v[hi-1];var store=lo
    for i in range(lo,hi-1):if v[i]<=pivot:let t=v[store];v[store]=v[i];v[i]=t;store+=1
    let t=v[store];v[store]=v[hi-1];v[hi-1]=t
    return store
@export("quick_sort_iterative")
fn quick_sort_iterative(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if v==UnsafePointer[Int64,MutAnyOrigin]() or n<2 or n>1024:return
    var stack=InlineArray[Int,32]();var top=0;var lo=0;var hi=Int(n)
    while True:
        while hi-lo>1:
            let p=qsi_partition(v,lo,hi)
            let left=p-lo;let right=hi-(p+1)
            if left<right:
                if right>1:stack[top]=p+1;stack[top+1]=hi;top+=2
                hi=p
            else:
                if left>1:stack[top]=lo;stack[top+1]=p;top+=2
                lo=p+1
        if top==0:break
        top-=2;lo=stack[top];hi=stack[top+1]
