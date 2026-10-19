from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn li_cross(ax:Int64,ay:Int64,bx:Int64,by:Int64,cx:Int64,cy:Int64)->Int64:return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
fn li_same(ax:Int64,ay:Int64,bx:Int64,by:Int64)->Bool:return ax==bx and ay==by
fn li_on(ax:Int64,ay:Int64,bx:Int64,by:Int64,x:Int64,y:Int64)->Bool:
    return li_cross(ax,ay,bx,by,x,y)==0 and x>=min(ax,bx) and x<=max(ax,bx) and y>=min(ay,by) and y<=max(ay,by)
fn li_write(out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t,x:Float64,y:Float64)->Int64:
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    let a=bitcast[UInt64](x);let b=bitcast[UInt64](y)
    for j in range(8):out[j]=UInt8((a>>(8*j))&255);out[8+j]=UInt8((b>>(8*j))&255)
    return 1
@export("line_intersection")
fn line_intersection(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=9 or (v[8]!=0 and v[8]!=1):return -1
    for i in range(8):
        if v[i]<-10000 or v[i]>10000:return -1
    let px=v[0];let py=v[1];let pxx=v[2];let pyy=v[3];let qx=v[4];let qy=v[5];let qxx=v[6];let qyy=v[7];let seg=v[8]==1
    let pp=li_same(px,py,pxx,pyy);let qp=li_same(qx,qy,qxx,qyy)
    if not seg and (pp or qp):return -1
    if seg and pp and qp:return if li_same(px,py,qx,qy):li_write(out,cap,Float64(px),Float64(py)) else:0
    if seg and pp:return if li_on(qx,qy,qxx,qyy,px,py):li_write(out,cap,Float64(px),Float64(py)) else:0
    if seg and qp:return if li_on(px,py,pxx,pyy,qx,qy):li_write(out,cap,Float64(qx),Float64(qy)) else:0
    let den=(px-pxx)*(qy-qyy)-(py-pyy)*(qx-qxx)
    if den==0:return 0
    let dp=px*pyy-py*pxx;let dq=qx*qyy-qy*qxx
    let nx=dp*(qx-qxx)-(px-pxx)*dq;let ny=dp*(qy-qyy)-(py-pyy)*dq
    if seg:
        let posden=if den<0:-den else:den;let posx=if den<0:-nx else:nx;let posy=if den<0:-ny else:ny
        let minx=max(min(px,pxx),min(qx,qxx));let maxx=min(max(px,pxx),max(qx,qxx));let miny=max(min(py,pyy),min(qy,qyy));let maxy=min(max(py,pyy),max(qy,qyy))
        if posx<minx*posden or posx>maxx*posden or posy<miny*posden or posy>maxy*posden:return 0
        return li_write(out,cap,Float64(posx)/Float64(posden),Float64(posy)/Float64(posden))
    return li_write(out,cap,Float64(nx)/Float64(den),Float64(ny)/Float64(den))
