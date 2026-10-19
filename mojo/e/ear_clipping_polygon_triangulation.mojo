from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn ear_cross(xs:List[Int64],ys:List[Int64],a:Int,b:Int,c:Int)->Int64:
    return (xs[b]-xs[a])*(ys[c]-ys[a])-(ys[b]-ys[a])*(xs[c]-xs[a])
fn ear_between(a:Int64,b:Int,x:Int64)->Bool:
    return x>=min(a,b) and x<=max(a,b)
fn ear_on_segment(xs:List[Int64],ys:List[Int64],a:Int,b:Int,p:Int)->Bool:
    return ear_cross(xs,ys,a,b,p)==0 and ear_between(xs[a],xs[b],xs[p]) and ear_between(ys[a],ys[b],ys[p])
fn ear_segments_intersect(xs:List[Int64],ys:List[Int64],a:Int,b:Int,c:Int,d:Int)->Bool:
    let o1=ear_cross(xs,ys,a,b,c);let o2=ear_cross(xs,ys,a,b,d);let o3=ear_cross(xs,ys,c,d,a);let o4=ear_cross(xs,ys,c,d,b)
    if ((o1>0 and o2<0) or (o1<0 and o2>0)) and ((o3>0 and o4<0) or (o3<0 and o4>0)):return True
    return (o1==0 and ear_on_segment(xs,ys,a,b,c)) or (o2==0 and ear_on_segment(xs,ys,a,b,d)) or (o3==0 and ear_on_segment(xs,ys,c,d,a)) or (o4==0 and ear_on_segment(xs,ys,c,d,b))
fn ear_put_u32(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int):
    let bits=UInt32(value)
    for b in range(4):output[offset+b]=UInt8((bits>>UInt(8*b))&255)

@export("ear_clipping_polygon_triangulation")
fn ear_clipping_polygon_triangulation(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<6 or length>128 or length%2!=0:return -1
    let n=Int(length)//2
    var xs=List[Int64](capacity=n);var ys=List[Int64](capacity=n)
    for i in range(n):
        let x=input[2*i];let y=input[2*i+1]
        if x< -10000 or x>10000 or y< -10000 or y>10000:return -1
        for j in range(i):if xs[j]==x and ys[j]==y:return -1
        xs.append(x);ys.append(y)
    var area:Int64=0
    for i in range(n):
        let j=(i+1)%n;area+=xs[i]*ys[j]-ys[i]*xs[j]
        if ear_cross(xs,ys,(i+n-1)%n,i,j)==0:return -1
    if area==0:return -1
    for i in range(n):
        let i2=(i+1)%n
        for j in range(i+1,n):
            let j2=(j+1)%n
            if i==j or i2==j or j2==i:continue
            if ear_segments_intersect(xs,ys,i,i2,j,j2):return -1
    let winding=1 if area>0 else -1
    var live=List[Int](capacity=n);for i in range(n):live.append(i)
    var triangles=List[Int](capacity=3*(n-2))
    while len(live)>3:
        var found=False
        for pos in range(len(live)):
            let prev=live[(pos+len(live)-1)%len(live)];let curr=live[pos];let next=live[(pos+1)%len(live)]
            if Int64(winding)*ear_cross(xs,ys,prev,curr,next)<=0:continue
            var contains=False
            for k in range(len(live)):
                let p=live[k]
                if p==prev or p==curr or p==next:continue
                let c1=Int64(winding)*ear_cross(xs,ys,prev,curr,p)
                let c2=Int64(winding)*ear_cross(xs,ys,curr,next,p)
                let c3=Int64(winding)*ear_cross(xs,ys,next,prev,p)
                if c1>=0 and c2>=0 and c3>=0:contains=True;break
            if contains:continue
            triangles.append(prev);triangles.append(curr);triangles.append(next)
            for k in range(pos,len(live)-1):live[k]=live[k+1]
            live.pop();found=True;break
        if not found:return -1
    triangles.append(live[0]);triangles.append(live[1]);triangles.append(live[2])
    let required=len(triangles)*4
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required):return -2
    for i in range(len(triangles)):ear_put_u32(output,i*4,triangles[i])
    return Int64(n-2)
