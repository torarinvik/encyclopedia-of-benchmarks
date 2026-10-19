from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("logistic_regression_predict")
fn logistic_regression_predict(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2051:return -1
    let rows=v[0];let f=v[1]
    if rows<1 or rows>63 or f<1 or f>32 or n!=c_size_t(2+rows*f+f):return -1
    let theta=2+Int(rows*f)
    for i in range(Int(rows*f+f)):
        if v[2+i] < -1000 or v[2+i]>1000:return -1
    var mask:UInt64=0
    for r in range(Int(rows)):
        var score:Int64=0
        for c in range(Int(f)):score+=v[2+r*Int(f)+c]*v[theta+c]
        if score>=0:mask|=UInt64(1)<<r
    return Int64(mask)
