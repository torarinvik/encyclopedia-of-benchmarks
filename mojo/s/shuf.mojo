from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("shuf")
fn shuf(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let count=a[0];let k=a[1];if count<0 or count>32 or k<1 or k>32 or n!=c_size_t(2+2*count):return -1
    var items=InlineArray[Int32,32]();var sample=InlineArray[Int32,32]();var occupied=InlineArray[Bool,32]()
    for i in range(Int(count)):if a[i+2]< -2147483648 or a[i+2]>2147483647:return -1;items[i]=Int32(a[i+2])
    let init=min(Int(count),Int(k))
    for i in range(init):
        let d=a[2+Int(count)+i];if d<0 or d>=k:return -1
        var slot=Int(d);while occupied[slot]:slot=(slot+1)%Int(k)
        sample[slot]=items[i];occupied[slot]=True
    if count>=k:
        for i in range(Int(k),Int(count)):
            let d=a[2+Int(count)+i];if d<0 or d>i:return -1
            if d<k:sample[Int(d)]=items[i]
    let bytes=init*4;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var p=0;for i in range(Int(k)):if occupied[i]:let z=bitcast[UInt32](sample[i]);for b in range(4):o[p*4+b]=UInt8((z>>UInt(8*b))&255);p+=1
    return Int64(p)
