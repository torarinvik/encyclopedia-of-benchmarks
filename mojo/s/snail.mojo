from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("snail")
fn snail(a:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int32,ImmutAnyOrigin]() or n<2 or n>259:return -1
    let rows=a[0];let cols=a[1]
    if rows<0 or rows>16 or cols<0 or cols>16 or (rows==0 and cols!=0) or (cols==1 and rows!=1) or n!=c_size_t(2+rows*cols):return -1
    let count=Int(rows*cols);let bytes=count*4;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var top=0;var bottom=Int(rows)-1;var left=0;var right=Int(cols)-1;var k=0
    while top<=bottom and left<=right:
        for c in range(left,right+1):let v=bitcast[UInt32](a[2+top*Int(cols)+c]);for b in range(4):o[k*4+b]=UInt8((v>>(8*b))&255);k+=1
        top+=1
        for r in range(top,bottom+1):let v=bitcast[UInt32](a[2+r*Int(cols)+right]);for b in range(4):o[k*4+b]=UInt8((v>>(8*b))&255);k+=1
        right-=1
        if top<=bottom:
            for c in range(right,left-1,-1):let v=bitcast[UInt32](a[2+bottom*Int(cols)+c]);for b in range(4):o[k*4+b]=UInt8((v>>(8*b))&255);k+=1
            bottom-=1
        if left<=right:
            for r in range(bottom,top-1,-1):let v=bitcast[UInt32](a[2+r*Int(cols)+left]);for b in range(4):o[k*4+b]=UInt8((v>>(8*b))&255);k+=1
            left+=1
    return bytes
