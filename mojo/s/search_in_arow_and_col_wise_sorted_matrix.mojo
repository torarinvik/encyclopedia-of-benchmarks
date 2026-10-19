from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("search_in_arow_and_col_wise_sorted_matrix")
fn search_in_arow_and_col_wise_sorted_matrix(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>3971:return -1
    let d=a[0];let target=a[1]
    if d<1 or d>63 or target< -2147483648 or target>2147483647 or n!=c_size_t(2+d*d):return -1
    var found=0;var fr= -1;var fc= -1;var occurrences=0
    for r in range(Int(d)):
        for c in range(Int(d)):
            let v=a[2+r*Int(d)+c]
            if v< -2147483648 or v>2147483647:return -1
            if c>0 and v<a[2+r*Int(d)+c-1]:return -1
            if r>0 and v<a[2+(r-1)*Int(d)+c]:return -1
            if v==target:occurrences+=1;if occurrences>1:return -1
    var r=0;var c=Int(d)-1
    while r<Int(d) and c>=0:
        let v=a[2+r*Int(d)+c]
        if v==target:found=1;fr=r;fc=c;break
        if v<target:r+=1
        else:c-=1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    let x=bitcast[UInt32](Int32(fr));let y=bitcast[UInt32](Int32(fc))
    for j in range(4):o[j]=UInt8((x>>UInt(8*j))&255);o[4+j]=UInt8((y>>UInt(8*j))&255)
    return found
