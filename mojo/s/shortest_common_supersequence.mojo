from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("shortest_common_supersequence")
fn shortest_common_supersequence(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>130:return -1
    let m=a[0];let k=a[1];if m<0 or m>64 or k<0 or k>64 or n!=c_size_t(2+m+k):return -1
    for i in range(Int(m+k)):if a[i+2]<32 or a[i+2]>126:return -1
    var dp=InlineArray[Int32,4225]()
    for i in range(1,Int(m)+1):for j in range(1,Int(k)+1):
        dp[i*65+j]=if a[i+1]==a[Int(m)+j+1] then dp[(i-1)*65+j-1]+1 else max(dp[(i-1)*65+j],dp[i*65+j-1])
    var rev=InlineArray[UInt8,128]();var used=0;var i=Int(m);var j=Int(k)
    while i>0 and j>0:
        if a[i+1]==a[Int(m)+j+1]:rev[used]=UInt8(a[i+1]);used+=1;i-=1;j-=1
        elif dp[(i-1)*65+j]>dp[i*65+j-1]:rev[used]=UInt8(a[i+1]);used+=1;i-=1
        else:rev[used]=UInt8(a[Int(m)+j+1]);used+=1;j-=1
    while i>0:rev[used]=UInt8(a[i+1]);used+=1;i-=1
    while j>0:rev[used]=UInt8(a[Int(m)+j+1]);used+=1;j-=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(used):return -2
    for z in range(used):o[z]=rev[used-1-z]
    return Int64(used)
