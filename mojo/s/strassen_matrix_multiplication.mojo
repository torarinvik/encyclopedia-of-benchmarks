from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn strassen(a:UnsafePointer[Int64,ImmutAnyOrigin],b:UnsafePointer[Int64,ImmutAnyOrigin],c:UnsafePointer[Int64,MutAnyOrigin],n:Int):
    if n==1:c[0]=a[0]*b[0];return
    let h=n/2;var x=InlineArray[Int64,16](fill=0);var y=InlineArray[Int64,16](fill=0)
    var m1=InlineArray[Int64,16](fill=0);var m2=InlineArray[Int64,16](fill=0);var m3=InlineArray[Int64,16](fill=0);var m4=InlineArray[Int64,16](fill=0);var m5=InlineArray[Int64,16](fill=0);var m6=InlineArray[Int64,16](fill=0);var m7=InlineArray[Int64,16](fill=0)
    for r in range(h):
        for col in range(h):
            let i=r*h+col;x[i]=a[r*n+col]+a[(r+h)*n+col+h];y[i]=b[r*n+col]+b[(r+h)*n+col+h]
    strassen(x.unsafe_ptr(),y.unsafe_ptr(),m1.unsafe_ptr(),h)
    for r in range(h):
        for col in range(h):
            let i=r*h+col;x[i]=a[(r+h)*n+col]+a[(r+h)*n+col+h];y[i]=b[r*n+col]
    strassen(x.unsafe_ptr(),y.unsafe_ptr(),m2.unsafe_ptr(),h)
    for r in range(h):
        for col in range(h):
            let i=r*h+col;x[i]=a[r*n+col];y[i]=b[r*n+col+h]-b[(r+h)*n+col+h]
    strassen(x.unsafe_ptr(),y.unsafe_ptr(),m3.unsafe_ptr(),h)
    for r in range(h):
        for col in range(h):
            let i=r*h+col;x[i]=a[(r+h)*n+col+h];y[i]=b[(r+h)*n+col]-b[r*n+col]
    strassen(x.unsafe_ptr(),y.unsafe_ptr(),m4.unsafe_ptr(),h)
    for r in range(h):
        for col in range(h):
            let i=r*h+col;x[i]=a[r*n+col]+a[r*n+col+h];y[i]=b[(r+h)*n+col+h]
    strassen(x.unsafe_ptr(),y.unsafe_ptr(),m5.unsafe_ptr(),h)
    for r in range(h):
        for col in range(h):
            let i=r*h+col;x[i]=a[(r+h)*n+col]-a[r*n+col];y[i]=b[r*n+col]+b[r*n+col+h]
    strassen(x.unsafe_ptr(),y.unsafe_ptr(),m6.unsafe_ptr(),h)
    for r in range(h):
        for col in range(h):
            let i=r*h+col;x[i]=a[r*n+col+h]-a[(r+h)*n+col+h];y[i]=b[(r+h)*n+col]+b[(r+h)*n+col+h]
    strassen(x.unsafe_ptr(),y.unsafe_ptr(),m7.unsafe_ptr(),h)
    for r in range(h):
        for col in range(h):
            let i=r*h+col;c[r*n+col]=m1[i]+m4[i]-m5[i]+m7[i];c[r*n+col+h]=m3[i]+m5[i];c[(r+h)*n+col]=m2[i]+m4[i];c[(r+h)*n+col+h]=m1[i]-m2[i]+m3[i]+m6[i]
@export("strassen_matrix_multiplication")
fn strassen_matrix_multiplication(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129:return -1
    let nv=v[0]
    if nv!=1 and nv!=2 and nv!=4 and nv!=8:return -1
    let size=Int(nv);let cells=size*size
    if n!=c_size_t(1+2*cells):return -1
    for i in range(1,Int(n)):if v[i]< -2 or v[i]>2:return -1
    let bytes=cells*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var c=InlineArray[Int64,64](fill=0);let a=UnsafePointer[Int64,ImmutAnyOrigin](v.unsafe_ptr().offset(1));let b=UnsafePointer[Int64,ImmutAnyOrigin](v.unsafe_ptr().offset(1+cells))
    strassen(a,b,c.unsafe_ptr(),size)
    for i in range(cells):let bits=bitcast[UInt64](c[i]);for by in range(8):o[i*8+by]=UInt8((bits>>UInt(8*by))&255)
    return Int64(bytes)
