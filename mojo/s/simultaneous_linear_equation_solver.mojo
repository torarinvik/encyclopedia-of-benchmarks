from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from math import floor, fma
fn sle_finite(m:UnsafePointer[Float64,MutAnyOrigin],n:Int)->Bool:
    for r in range(n):
        for c in range(n+1):if not m[r*6+c].is_finite():return False
    return True
fn sle_simplify(m:UnsafePointer[Float64,MutAnyOrigin],n:Int)->Bool:
    if n<2 or m[0]==0.0:return False
    for r in range(n):
        let mag=m[r*6]
        if mag!=0.0:
            for c in range(n+1):m[r*6+c]/=mag
    if not sle_finite(m,n):return False
    var first=InlineArray[Float64,6]();var col=InlineArray[Float64,5]()
    for c in range(n+1):first[c]=m[c]
    for r in range(1,n):
        if m[r*6]!=0.0:
            for c in range(n+1):m[r*6+c]=first[c]-m[r*6+c]
    if not sle_finite(m,n):return False
    if n>2:
        var next=InlineArray[Float64,30]()
        for r in range(1,n):
            col[r-1]=m[r*6]
            for c in range(1,n+1):next[(r-1)*6+c-1]=m[r*6+c]
        if not sle_simplify(next.unsafe_ptr(),n-1):return False
        for c in range(n+1):m[c]=first[c]
        for r in range(1,n):
            m[r*6]=col[r-1]
            for c in range(1,n+1):m[r*6+c]=next[(r-1)*6+c-1]
    return sle_finite(m,n)
fn sle_round(value:Float64)->Int64:
    let x=value*100000.0;let lo=floor(x);let mid=lo+0.5
    let side=fma(value,100000.0,-mid)
    var v=Int64(lo)
    if side>0.0 or (side==0.0 and v%2!=0):v+=1
    let projected=(Float64(v)/100000.0)*100000.0;let pl=floor(projected);let pm=pl+0.5
    var t=Int64(pl)
    if projected>pm or (projected==pm and t%2!=0):t+=1
    return t
fn sle_put(o:UnsafePointer[UInt8,MutAnyOrigin],off:Int,v:Int64):
    let bits=UInt64(v)
    for b in range(8):o[off+b]=UInt8((bits>>(8*b))&255)
@export("simultaneous_linear_equation_solver")
fn simultaneous_linear_equation_solver(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>31:return -1
    let nv=a[0];if nv<1 or nv>5:return -1
    let d=Int(nv);if n!=c_size_t(1+d*(d+1)):return -1
    var m=InlineArray[Float64,30]();var haszero=false
    for r in range(d):
        for c in range(d+1):
            let v=a[1+r*(d+1)+c];if v< -100000 or v>100000:return -1
            m[r*6+c]=Float64(v)/1000.0;if v==0:haszero=true
    if d==1:
        if m[0]==0.0:return -1
    else:
        if haszero:
            var full=d
            for r in range(d):
                var ok=true
                for c in range(d+1):if m[r*6+c]==0.0:ok=false
                if ok and full==d:full=r
            if full==d:return -1
            if full!=0:
                var saved=InlineArray[Float64,6]();for c in range(d+1):saved[c]=m[full*6+c]
                for r in range(full,0,-1):for c in range(d+1):m[r*6+c]=m[(r-1)*6+c]
                for c in range(d+1):m[c]=saved[c]
        if not sle_simplify(m.unsafe_ptr(),d):return -1
    var sol=InlineArray[Float64,5]()
    for ri in range(d):
        let r=d-1-ri;if m[r*6+r]==0.0:return -1
        var value=m[r*6+d]
        for c in range(r+1,d):value-=m[r*6+c]*sol[c]
        value/=m[r*6+r];if not value.is_finite():return -1
        sol[r]=value
    var ticks=InlineArray[Int64,5]()
    for i in range(d):
        let scaled=sol[i]*100000.0
        if not scaled.is_finite() or scaled<=-4503599627370496.0 or scaled>=4503599627370496.0:return -1
        let t=sle_round(sol[i]);if t< -2251799813685248 or t>2251799813685248:return -1
        ticks[i]=t
    let needed=8+8*d;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(needed):return -2
    sle_put(o,0,nv);for i in range(d):sle_put(o,8+8*i,ticks[i])
    return needed
