from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("largest_rectangle_histogram")
fn largest_rectangle_histogram(h: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if n==0:return 0
    if h==UnsafePointer[Int64, ImmutAnyOrigin]() or n>64:return -9223372036854775808
    for i in range(Int(n)):
        if h[i]<0 or h[i]>1000000:return -9223372036854775808
    var stack=InlineArray[Int64,64](fill=0);var top=0;var best:Int64=0
    for i in range(Int(n)):
        while top>0 and h[stack[top-1]]>h[i]:
            top-=1;let bar=Int(stack[top]);let left=if top==0:0 else:Int(stack[top-1])+1
            best=max(best,h[bar]*Int64(i-left))
        stack[top]=Int64(i);top+=1
    while top>0:
        top-=1;let bar=Int(stack[top]);let left=if top==0:0 else:Int(stack[top-1])+1
        best=max(best,h[bar]*Int64(Int(n)-left))
    return best
