from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("skytale_cipher")
fn skytale_cipher(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>260:return -1
    let mode=a[0];let key=a[1];let count=a[2]
    if (mode!=0 and mode!=1) or key<1 or key>256 or count<0 or count>256 or n!=c_size_t(3+count):return -1
    for i in range(Int(count)):if a[i+3]<0 or a[i+3]>127:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(count):return -2
    if mode==0:
        var out=0
        for row in range(Int(key)):
            var p=row
            while p<Int(count):o[out]=UInt8(a[p+3]);out+=1;p+=Int(key)
    else:
        let base=Int(count/key);let extra=Int(count%key);var starts=InlineArray[Int32,256]();var used=InlineArray[Int32,256]()
        for r in range(1,Int(key)):starts[r]=starts[r-1]+base+(1 if r-1<extra else 0)
        for p in range(Int(count)):
            let row=p%Int(key);o[p]=UInt8(a[Int(starts[row]+used[row])+3]);used[row]+=1
    return count
