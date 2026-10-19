from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("sliding_window_maximum")
fn sliding_window_maximum(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1026:return -1
    let count=a[0];let k=a[1];if count<0 or count>1024 or k<1 or k>1024 or n!=c_size_t(count+2):return -1
    for i in range(Int(count)):if a[i+2]< -2147483648 or a[i+2]>2147483647:return -1
    let windows=Int(count-k+1) if count>=k else 0;let bytes=windows*8
    var deque=InlineArray[Int32,1024]();var head=0;var tail=0;var vals=InlineArray[Int64,1024]()
    for i in range(Int(count)):
        while head<tail and deque[head]<=i-Int(k):head+=1
        while head<tail and a[Int(deque[tail-1])+2]<a[i+2]:tail-=1
        deque[tail]=Int32(i);tail+=1
        if i>=Int(k)-1:vals[i-Int(k)+1]=a[Int(deque[head])+2]
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(windows):
        let bits=UInt64(vals[i]);for b in range(8):o[i*8+b]=UInt8((bits>>(b*8))&255)
    return windows
