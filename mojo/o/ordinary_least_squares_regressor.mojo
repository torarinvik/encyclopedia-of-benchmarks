from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import abs
fn olsr2_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let b=bitcast[UInt64](x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("ordinary_least_squares_regressor")
fn ordinary_least_squares_regressor(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6:return -1
    let rows=Int(v[0]);let features=v[1];let tests=Int(v[2])
    if rows<2 or rows>8 or features!=2 or tests<1 or tests>3 or n!=c_size_t(3+rows*3+tests*2):return -1
    var a=InlineArray[Float64,9](fill=0.0);var b=InlineArray[Float64,3](fill=0.0);var p=3
    for r in range(rows):
        let x0=v[p];let x1=v[p+1];let y=v[p+2];p+=3
        if x0 < -100 or x0>100 or x1 < -100 or x1>100 or y < -1000 or y>1000:return -1
        var z=InlineArray[Float64,3](fill=0.0);z[0]=Float64(x0);z[1]=Float64(x1);z[2]=1.0
        for i in range(3):
            b[i]+=z[i]*Float64(y)
            for j in range(3):a[i*3+j]+=z[i]*z[j]
    for c in range(3):
        var pivot=c
        for r in range(c+1,3):if abs(a[r*3+c])>abs(a[pivot*3+c]):pivot=r
        if abs(a[pivot*3+c])<1.0e-12:return -1
        for j in range(3):let t=a[c*3+j];a[c*3+j]=a[pivot*3+j];a[pivot*3+j]=t
        let t=b[c];b[c]=b[pivot];b[pivot]=t;let scale=a[c*3+c]
        for j in range(c,3):a[c*3+j]/=scale
        b[c]/=scale
        for r in range(3):
            if r!=c:
                let factor=a[r*3+c]
                for j in range(c,3):a[r*3+j]-=factor*a[c*3+j]
                b[r]-=factor*b[c]
    var predictions=InlineArray[Float64,3](fill=0.0)
    for r in range(tests):
        let x0=v[p];let x1=v[p+1];p+=2
        if x0 < -100 or x0>100 or x1 < -100 or x1>100:return -1
        predictions[r]=Float64(x0)*b[0]+Float64(x1)*b[1]+b[2]
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(tests*8):return -2
    for r in range(tests):olsr2_put(o,r*8,predictions[r])
    return Int64(tests*8)
