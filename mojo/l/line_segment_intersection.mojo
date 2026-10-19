from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn seg_orient(ax:Int64,ay:Int64,bx:Int64,by:Int64,cx:Int64,cy:Int64)->Int64:return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
fn seg_on(ax:Int64,ay:Int64,bx:Int64,by:Int64,x:Int64,y:Int64)->Bool:
    return x>=min(ax,bx) and x<=max(ax,bx) and y>=min(ay,by) and y<=max(ay,by)
@export("line_segment_intersection")
fn line_segment_intersection(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=8:return -1
    for i in range(8):
        if v[i]<-10000 or v[i]>10000:return -1
    let a=seg_orient(v[0],v[1],v[2],v[3],v[4],v[5]);let b=seg_orient(v[0],v[1],v[2],v[3],v[6],v[7]);let c=seg_orient(v[4],v[5],v[6],v[7],v[0],v[1]);let d=seg_orient(v[4],v[5],v[6],v[7],v[2],v[3])
    let proper=((a<0 and b>0) or (a>0 and b<0)) and ((c<0 and d>0) or (c>0 and d<0))
    let touches=(a==0 and seg_on(v[0],v[1],v[2],v[3],v[4],v[5])) or (b==0 and seg_on(v[0],v[1],v[2],v[3],v[6],v[7])) or (c==0 and seg_on(v[4],v[5],v[6],v[7],v[0],v[1])) or (d==0 and seg_on(v[4],v[5],v[6],v[7],v[2],v[3]))
    return Int64(proper or touches)
