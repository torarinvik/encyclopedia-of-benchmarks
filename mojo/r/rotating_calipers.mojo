from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from math import sqrt
fn cross_idx(ox:Int64,oy:Int64,ax:Int64,ay:Int64,bx:Int64,by:Int64)->Int64:
    return (ax-ox)*(by-oy)-(ay-oy)*(bx-ox)
fn dist2(ax:Int64,ay:Int64,bx:Int64,by:Int64)->UInt64:
    let dx=ax-bx;let dy=ay-by
    return UInt64(dx*dx)+UInt64(dy*dy)
@export("rotating_calipers")
fn rotating_calipers(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>2049 or n%2==0:return -1.0e300
    let count=v[0];if count<2 or count>1024 or Int(n)!=1+2*Int(count):return -1.0e300
    let size=Int(count);var xs=InlineArray[Int64,1024](fill=0);var ys=InlineArray[Int64,1024](fill=0)
    for i in range(size):
        let x=v[1+2*i];let y=v[2+2*i]
        if x< -1000000000 or x>1000000000 or y< -1000000000 or y>1000000000:return -1.0e300
        xs[i]=x;ys[i]=y
    for i in range(1,size):
        let x=xs[i];let y=ys[i];var j=i
        while j>0 and (xs[j-1]>x or (xs[j-1]==x and ys[j-1]>y)):
            xs[j]=xs[j-1];ys[j]=ys[j-1];j-=1
        xs[j]=x;ys[j]=y
    var unique=0
    for i in range(size):
        if unique==0 or xs[i]!=xs[unique-1] or ys[i]!=ys[unique-1]:xs[unique]=xs[i];ys[unique]=ys[i];unique+=1
    if unique==1:return 0.0
    var lx=InlineArray[Int64,2048](fill=0);var ly=InlineArray[Int64,2048](fill=0);var ln=0
    for i in range(unique):
        while ln>=2 and cross_idx(lx[ln-2],ly[ln-2],lx[ln-1],ly[ln-1],xs[i],ys[i])<=0:ln-=1
        lx[ln]=xs[i];ly[ln]=ys[i];ln+=1
    var ux=InlineArray[Int64,2048](fill=0);var uy=InlineArray[Int64,2048](fill=0);var un=0
    for j in range(unique):
        let i=unique-1-j
        while un>=2 and cross_idx(ux[un-2],uy[un-2],ux[un-1],uy[un-1],xs[i],ys[i])<=0:un-=1
        ux[un]=xs[i];uy[un]=ys[i];un+=1
    ln-=1;un-=1
    var hx=InlineArray[Int64,2048](fill=0);var hy=InlineArray[Int64,2048](fill=0);var h=0
    for i in range(ln):hx[h]=lx[i];hy[h]=ly[i];h+=1
    for i in range(un):hx[h]=ux[i];hy[h]=uy[i];h+=1
    if h==2:return sqrt(Float64(dist2(hx[0],hy[0],hx[1],hy[1])))
    var antipodal=1;var advances=0
    while advances<h and cross_idx(hx[0],hy[0],hx[1],hy[1],hx[(antipodal+1)%h],hy[(antipodal+1)%h])>cross_idx(hx[0],hy[0],hx[1],hy[1],hx[antipodal],hy[antipodal]):antipodal=(antipodal+1)%h;advances+=1
    var maximum:UInt64=0
    for current in range(h):
        let next=(current+1)%h;advances=0
        while advances<h and cross_idx(hx[current],hy[current],hx[next],hy[next],hx[(antipodal+1)%h],hy[(antipodal+1)%h])>cross_idx(hx[current],hy[current],hx[next],hy[next],hx[antipodal],hy[antipodal]):antipodal=(antipodal+1)%h;advances+=1
        let after=(antipodal+1)%h
        let d1=dist2(hx[current],hy[current],hx[antipodal],hy[antipodal]);let d2=dist2(hx[next],hy[next],hx[antipodal],hy[antipodal]);let d3=dist2(hx[current],hy[current],hx[after],hy[after]);let d4=dist2(hx[next],hy[next],hx[after],hy[after])
        if d1>maximum:maximum=d1
        if d2>maximum:maximum=d2
        if d3>maximum:maximum=d3
        if d4>maximum:maximum=d4
    return sqrt(Float64(maximum))
