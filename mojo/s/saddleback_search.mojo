from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("saddleback_search")
fn saddleback_search(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>1027:return -1
    let r=a[0];let c=a[1];let t=a[2]
    if r<1 or r>32 or c<1 or c>32 or t< -2147483648 or t>2147483647 or n!=c_size_t(3+r*c):return -1
    for i in range(Int(r*c)):
        let v=a[3+i]
        if v< -2147483648 or v>2147483647:return -1
        let row=i/Int(c);let col=i%Int(c)
        if col>0 and v<=a[3+i-1]:return -1
        if row>0 and v<=a[3+i-Int(c)]:return -1
    var row=0;var col=Int(c)-1
    while row<Int(r):
        let v=a[3+row*Int(c)+col]
        if v==t:return Int64(row*Int(c)+col+1)
        if v<t:row+=1
        elif col==0:break
        else:col-=1
    return 0
