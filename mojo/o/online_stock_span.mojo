from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn oss_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("online_stock_span")
fn online_stock_span(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[0]<1 or v[0]>4095 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0])
    for i in range(count):if v[i+1]<1 or v[i+1]>100000:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    var stack=InlineArray[Int64,4095](fill=0);var top=0
    for day in range(count):
        let price=v[day+1]
        while top>0 and v[Int(stack[top-1])+1]<=price:top-=1
        let span=if top==0:day+1 else:day-Int(stack[top-1])
        oss_put(o,day*8,Int64(span));stack[top]=Int64(day);top+=1
    return Int64(count)
