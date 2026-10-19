from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("unique_paths_with_obstacles")
fn unique_paths_with_obstacles(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>402:return -1
    let rows=v[0]; let cols=v[1]
    if rows<1 or rows>20 or cols<1 or cols>20 or n!=c_size_t(2+rows*cols):return -1
    for i in range(Int(rows*cols)):if v[2+i]!=0 and v[2+i]!=1:return -1
    var dp=InlineArray[Int64,20](fill=0); dp[0]=1
    for r in range(Int(rows)):
        for c in range(Int(cols)):
            if v[2+r*Int(cols)+c]==1:dp[c]=0
            elif c>0:dp[c]+=dp[c-1]
    return dp[Int(cols)-1]
