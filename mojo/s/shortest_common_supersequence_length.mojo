from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("shortest_common_supersequence_length")
fn shortest_common_supersequence_length(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>512:return -1
    let m=a[0];let k=a[1];if m<0 or m>255 or k<0 or k>255 or n!=c_size_t(m+k+2):return -1
    for i in range(Int(m+k)):if a[i+2]<0 or a[i+2]>127:return -1
    var dp=InlineArray[Int32,65536]()
    for i in range(1,Int(m)+1):for j in range(1,Int(k)+1):dp[i*256+j]=if a[i+1]==a[Int(m)+j+1] then dp[(i-1)*256+j-1]+1 else max(dp[(i-1)*256+j],dp[i*256+j-1])
    return m+k-Int64(dp[Int(m)*256+Int(k)])
