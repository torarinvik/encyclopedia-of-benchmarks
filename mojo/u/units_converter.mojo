from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
comptime BAD:Float64=-1.0e300
fn addconv(pres:InlineArray[UInt8,64],sl:InlineArray[Float64,64],it:InlineArray[Float64,64],src:Int,dst:Int,s:Float64,b:Float64,count:Int)->(InlineArray[UInt8,64],InlineArray[Float64,64],InlineArray[Float64,64],Int):
    var p=pres;var a=sl;var c=it;var n=count
    if src==dst:return(p,a,c,n)
    let at=src*8+dst
    if p[at]==0:p[at]=1;a[at]=s;c[at]=b;n+=1
    return(p,a,c,n)
@export("units_converter")
fn units_converter(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4 or n>35:return BAD
    var unit_count=0;var source=Int64(0);var target=Int64(0);var micro=Int64(0)
    var present=InlineArray[UInt8,64](fill=0);var slopes=InlineArray[Float64,64](fill=0.0);var ints=InlineArray[Float64,64](fill=0.0);var known=0
    if v[0]==0:
        if n!=4:return BAD
        unit_count=6;source=v[1];target=v[2];micro=v[3]
        var es=InlineArray[Int,5](fill=0);var et=InlineArray[Int,5](fill=0);var ss=InlineArray[Float64,5](fill=0.0);var bb=InlineArray[Float64,5](fill=0.0)
        es[0]=0;et[0]=1;ss[0]=1.0;bb[0]= -273.15
        es[1]=1;et[1]=2;ss[1]=9.0/5.0;bb[1]=32.0
        es[2]=3;et[2]=1;ss[2]=5.0/4.0;bb[2]=0.0
        es[3]=4;et[3]=1;ss[3]= -2.0/3.0;bb[3]=100.0
        es[4]=5;et[4]=0;ss[4]=5.0/9.0;bb[4]=0.0
        for i in range(5):present[es[i]*8+et[i]]=1;slopes[es[i]*8+et[i]]=ss[i];ints[es[i]*8+et[i]]=bb[i];known+=1
    elif v[0]==1:
        if n<6:return BAD
        unit_count=Int(v[1]);let edges=v[2];source=v[3];target=v[4];micro=v[5]
        if unit_count<2 or unit_count>8 or edges<0 or edges>unit_count-1 or n!=c_size_t(6+4*edges):return BAD
        var parent=InlineArray[Int,8](fill=0);for i in range(unit_count):parent[i]=i
        for e in range(Int(edges)):
            let at=6+4*e;let a=v[at];let b=v[at+1];let sp=v[at+2];let ip=v[at+3]
            if a<0 or a>=unit_count or b<0 or b>=unit_count or a==b or sp==0 or sp < -5000000 or sp>5000000 or ip < -1000000000000 or ip>1000000000000:return BAD
            var ra=Int(a);while parent[ra]!=ra:ra=parent[ra]
            var rb=Int(b);while parent[rb]!=rb:rb=parent[rb]
            if ra==rb:return BAD
            parent[ra]=rb;let slot=Int(a)*8+Int(b);present[slot]=1;slopes[slot]=Float64(sp)/1000000.0;ints[slot]=Float64(ip)/1000000.0;known+=1
    else:return BAD
    if source<0 or source>=unit_count or target<0 or target>=unit_count or source==target or micro < -1000000000000 or micro>1000000000000:return BAD
    var stable=False
    for _ in range(9):
        var inverse=InlineArray[UInt8,64](fill=0);var islope=InlineArray[Float64,64](fill=0.0);var iint=InlineArray[Float64,64](fill=0.0);var ic=0
        for a in range(unit_count):
            for b in range(unit_count):
                let at=a*8+b
                if present[at]==0:continue
                (inverse,islope,iint,ic)=addconv(inverse,islope,iint,a,b,slopes[at],ints[at],ic)
                (inverse,islope,iint,ic)=addconv(inverse,islope,iint,b,a,1.0/slopes[at],-ints[at]/slopes[at],ic)
        var np=InlineArray[UInt8,64](fill=0);var ns=InlineArray[Float64,64](fill=0.0);var ni=InlineArray[Float64,64](fill=0.0);var nc=0
        for a in range(unit_count):
            for mid in range(unit_count):
                let first=a*8+mid
                if inverse[first]==0:continue
                (np,ns,ni,nc)=addconv(np,ns,ni,a,mid,islope[first],iint[first],nc)
                for b in range(unit_count):
                    let second=mid*8+b
                    if inverse[second]==0:continue
                    (np,ns,ni,nc)=addconv(np,ns,ni,a,b,islope[second]*islope[first],islope[second]*iint[first]+iint[second],nc)
        present=np;slopes=ns;ints=ni
        if nc==known:stable=True;break
        known=nc
    if not stable:return BAD
    let slot=Int(source)*8+Int(target)
    if present[slot]==0:return BAD
    return slopes[slot]*(Float64(micro)/1000000.0)+ints[slot]
