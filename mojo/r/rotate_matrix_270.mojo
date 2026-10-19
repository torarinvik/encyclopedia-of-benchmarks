from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn wr64rm(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(j*8))&UInt64(255))
fn rotate_mat(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t,mode:Int)->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>1027 or v[0]<1 or v[0]>32 or v[1]<1 or v[1]>32:return -1
    let rows=Int(v[0]);let cols=Int(v[1]);if Int(n)!=2+rows*cols:return -1
    var outrows=rows;var outcols=cols
    if mode!=0:outrows=cols;outcols=rows
    let bytes=8*(2+rows*cols)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    wr64rm(o,0,Int64(outrows));wr64rm(o,8,Int64(outcols))
    for r in range(rows):
        for c in range(cols):
            var rr=r;var cc=c
            if mode==0:rr=rows-1-r;cc=cols-1-c
            elif mode==1:rr=c;cc=rows-1-r
            elif mode==2:rr=cols-1-c;cc=r
            elif mode==3:rr=c;cc=r
            wr64rm(o,16+8*(rr*outcols+cc),v[2+r*cols+c])
    return Int64(bytes)
@export("rotate_matrix_270")
fn rotate_matrix_270(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    return rotate_mat(v,n,o,cap,2)
