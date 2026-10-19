from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn tri_emit(o:UnsafePointer[UInt8,MutAnyOrigin],p:UnsafePointer[Int32,MutAnyOrigin],x0:Int64,y0:Int64,x1:Int64,y1:Int64):
    let vals=InlineArray[Int64,4](x0,y0,x1,y1)
    for i in range(4):let z=bitcast[UInt64](vals[i]);for b in range(8):o[p[0]]=UInt8((z>>UInt(8*b))&255);p[0]+=1
fn tri_draw(o:UnsafePointer[UInt8,MutAnyOrigin],p:UnsafePointer[Int32,MutAnyOrigin],x1:Int64,y1:Int64,x2:Int64,y2:Int64,x3:Int64,y3:Int64,d:Int):
    tri_emit(o,p,x1,y1,x2,y2);tri_emit(o,p,x2,y2,x3,y3);tri_emit(o,p,x3,y3,x1,y1)
    if d==0:return
    let abx=(x1+x2)/2;let aby=(y1+y2)/2;let acx=(x1+x3)/2;let acy=(y1+y3)/2;let bcx=(x2+x3)/2;let bcy=(y2+y3)/2
    tri_draw(o,p,x1,y1,abx,aby,acx,acy,d-1);tri_draw(o,p,x2,y2,abx,aby,bcx,bcy,d-1);tri_draw(o,p,x3,y3,bcx,bcy,acx,acy,d-1)
@export("sierpinski_triangle")
fn sierpinski_triangle(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or a[0]<0 or a[0]>4:return -1
    var calls=1;for _ in range(Int(a[0])):calls=calls*3+1
    let bytes=calls*96;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var p=InlineArray[Int32,1]();tri_draw(o,p.unsafe_ptr(),-2800,-2000,0,2800,2800,-2000,Int(a[0]));return Int64(bytes)
