from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("stock_span_problem")
fn stock_span_problem(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let cv=v[0]
    if cv<1 or cv>64 or n!=c_size_t(cv+1):return -1
    let count=Int(cv)
    for i in range(count):if v[i+1]< -2147483648 or v[i+1]>2147483647:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count*8):return -2
    var st=InlineArray[Int,64](fill=0);var top=0;var spans=InlineArray[Int64,64](fill=0)
    for day in range(count):
        let price=v[day+1]
        while top>0 and v[st[top-1]+1]<=price:top-=1
        spans[day]=if top==0 then day+1 else day-st[top-1]
        st[top]=day;top+=1
    for i in range(count):let bits=bitcast[UInt64](spans[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(count)
