from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.math import fabs,hypot,isfinite,sqrt
fn rdp_py(points:InlineArray[Float64,24],a:Int,b:Int,k:Int)->Float64:
    let ax=points[2*a];let ay=points[2*a+1];let dx=points[2*b]-ax;let dy=points[2*b+1]-ay
    let px=points[2*k];let py=points[2*k+1];let l2=dx*dx+dy*dy;var t=((px-ax)*dx+(py-ay)*dy)/l2
    if t<0:t=0.0
    elif t>1:t=1.0
    let nx=ax+t*dx;let ny=ay+t*dy
    return hypot(px-nx,py-ny)
fn rdp_rust(points:InlineArray[Float64,24],a:Int,b:Int,k:Int,ll:Float64)->Float64:
    let ax=points[2*a];let ay=points[2*a+1];let bx=points[2*b];let by=points[2*b+1]
    let dx=bx-ax;let dy=by-ay;let px=points[2*k];let py=points[2*k+1]
    let numerator=dy*px-dx*py+bx*ay-by*ax
    return fabs(numerator)/ll
fn rdp_split(points:InlineArray[Float64,24],a:Int,b:Int,eps:Float64,mut keep:InlineArray[Int64,12]):
    if b<=a+1:return
    var best:Float64=0.0;var index=a
    for k in range(a+1,b):
        let dist=rdp_py(points,a,b,k)
        if dist>best:best=dist;index=k
    if best>eps:
        keep[index]=1;rdp_split(points,a,index,eps,keep);rdp_split(points,index,b,eps,keep)
@export("ramer_douglas_peucker")
fn ramer_douglas_peucker(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<2 or n>26:return -1
    for i in range(Int(n)):if not isfinite(v[i]):return -1
    let cv=v[0]
    if cv<0 or cv>12 or Float64(Int(cv))!=cv:return -1
    let count=Int(cv)
    if n!=c_size_t(2+2*count) or v[1]<0 or v[1]>100:return -1
    var points=InlineArray[Float64,24](fill=0.0)
    for i in range(2*count):
        if v[2+i]<-100 or v[2+i]>100:return -1
        points[i]=v[2+i]
    if count>=3:
        for i in range(count):
            for j in range(i):
                if points[2*i]==points[2*j] and points[2*i+1]==points[2*j+1]:return -1
        for i in range(count):
            for j in range(i+2,count):
                let ax=points[2*i];let ay=points[2*i+1];let dx=points[2*j]-ax;let dy=points[2*j+1]-ay;let l2=dx*dx+dy*dy;let ll=sqrt(l2)
                if not isfinite(l2) or l2<=0 or not isfinite(ll) or ll<=0:return -1
                var mp:Float64=0.0;var mr:Float64=0.0;var ip=i;var ir=i
                for k in range(i+1,j):
                    let px=points[2*k];let py=points[2*k+1];let t=((px-ax)*dx+(py-ay)*dy)/l2
                    if not (t>=0 and t<=1):return -1
                    let dp=rdp_py(points,i,j,k);let dr=rdp_rust(points,i,j,k,ll)
                    if not isfinite(dp) or not isfinite(dr):return -1
                    if dp>mp:mp=dp;ip=k
                    if dr>mr:mr=dr;ir=k
                if ip!=ir or ((mp>v[1])!=(mr>v[1])):return -1
    var keep=InlineArray[Int64,12](fill=0)
    if count>0:keep[0]=1
    if count>1:keep[count-1]=1
    if count>2:rdp_split(points,0,count-1,v[1],keep)
    var staged=InlineArray[Float64,25](fill=0.0);var outn=0
    for i in range(count):
        if keep[i]!=0:staged[1+2*outn]=points[2*i];staged[2+2*outn]=points[2*i+1];outn+=1
    staged[0]=Float64(outn);let needed=1+2*outn
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    for i in range(needed):o[i]=staged[i]
    return Int64(needed)
