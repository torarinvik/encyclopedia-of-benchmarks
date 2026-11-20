from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime CEE_MAX_N=6
comptime CEE_MAX_LEN=14
comptime CEE_MAX_TRI=4
comptime CEE_MAX_ALL=14
comptime CEE_MAX_DIAG=9
comptime CEE_MAX_TRIPLES=20

@fieldwise_init
struct CeePoint(Copyable):
    var x: Int64
    var y: Int64

@fieldwise_init
struct CeeTriangle(Copyable):
    var a: Int
    var b: Int
    var c: Int

@fieldwise_init
struct CeeTriangulation(Copyable):
    var triangles: InlineArray[CeeTriangle, CEE_MAX_TRI]
    var count: Int
    var edges: UInt64

@fieldwise_init
struct CeeFraction(Copyable):
    var num: Int64
    var den: Int64

@fieldwise_init
struct CeeMetrics(Copyable):
    var maximum: CeeFraction
    var worst: UInt64

fn cee_orient(a:CeePoint,b:CeePoint,c:CeePoint)->Int64:
    (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)

fn cee_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    while b!=0:
        let r=a%b;a=b;b=r
    a

fn cee_fraction(num:Int64,den:Int64)->CeeFraction:
    let g=cee_gcd(num,den)
    CeeFraction(num//g,den//g)

fn cee_compare(a:CeeFraction,b:CeeFraction)->Int:
    let x=a.num*b.den;let y=b.num*a.den
    if x<y:return -1
    if x>y:return 1
    0

fn cee_edge_bit(a:Int,b:Int)->UInt64:
    let lo=min(a,b);let hi=max(a,b)
    UInt64(1)<<UInt(lo*CEE_MAX_N+hi)

fn cee_crosses(p:InlineArray[CeePoint,CEE_MAX_N],a:Int,b:Int,c:Int,d:Int)->Bool:
    cee_orient(p[a],p[b],p[c])*cee_orient(p[a],p[b],p[d])<0 and cee_orient(p[c],p[d],p[a])*cee_orient(p[c],p[d],p[b])<0

fn cee_inside(p:InlineArray[CeePoint,CEE_MAX_N],t:CeeTriangle,v:Int)->Bool:
    let direction=cee_orient(p[t.a],p[t.b],p[t.c])
    cee_orient(p[t.a],p[t.b],p[v])*direction>0 and cee_orient(p[t.b],p[t.c],p[v])*direction>0 and cee_orient(p[t.c],p[t.a],p[v])*direction>0

fn cee_score(p:InlineArray[CeePoint,CEE_MAX_N],t:CeeTriangle,sides:inout InlineArray[Int64,3])->CeeFraction:
    let a=p[t.a];let b=p[t.b];let c=p[t.c]
    sides[0]=(b.x-c.x)*(b.x-c.x)+(b.y-c.y)*(b.y-c.y)
    sides[1]=(c.x-a.x)*(c.x-a.x)+(c.y-a.y)*(c.y-a.y)
    sides[2]=(a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)
    var k=0
    if sides[1]>sides[k]:k=1
    if sides[2]>sides[k]:k=2
    let other=sides[0]+sides[1]+sides[2]-sides[k]
    if sides[k]<=other:return CeeFraction(0,1)
    var area=cee_orient(a,b,c)
    if area<0:area = -area
    let difference=sides[k]-other
    cee_fraction(sides[k]*difference*difference,16*area*area)

fn cee_triangle_id(a:Int,b:Int,c:Int,n:Int)->Int:
    var id=0
    for x in range(n):
        for y in range(x+1,n):
            for z in range(y+1,n):
                if x==a and y==b and z==c:return id
                id+=1
    0

fn cee_evaluate(p:InlineArray[CeePoint,CEE_MAX_N],n:Int,t:CeeTriangulation)->CeeMetrics:
    var result=CeeMetrics(CeeFraction(0,1),0)
    for i in range(t.count):
        var sides=InlineArray[Int64,3](fill=0)
        let score=cee_score(p,t.triangles[i],sides)
        let comparison=cee_compare(score,result.maximum)
        let bit=UInt64(1)<<UInt(cee_triangle_id(t.triangles[i].a,t.triangles[i].b,t.triangles[i].c,n))
        if comparison>0:result.maximum=score;result.worst=bit
        elif comparison==0:result.worst=result.worst|bit
    result

fn cee_improves(a:CeeMetrics,b:CeeMetrics)->Bool:
    let comparison=cee_compare(a.maximum,b.maximum)
    comparison<0 or (comparison==0 and a.worst!=b.worst and (a.worst&b.worst)==a.worst)

fn cee_popcount(value:UInt64)->Int:
    var bits=value;var count=0
    while bits!=0:bits=bits&(bits-1);count+=1
    count

fn cee_preferable(a:CeeMetrics,b:CeeMetrics)->Bool:
    let comparison=cee_compare(a.maximum,b.maximum)
    if comparison!=0:return comparison<0
    let x=cee_popcount(a.worst);let y=cee_popcount(b.worst)
    x<y or (x==y and a.worst<b.worst)

fn cee_enumerate(p:InlineArray[CeePoint,CEE_MAX_N],n:Int,
                 out:inout InlineArray[CeeTriangulation,CEE_MAX_ALL])->Int:
    var da=InlineArray[Int,CEE_MAX_DIAG](fill=0);var db=InlineArray[Int,CEE_MAX_DIAG](fill=0);var m=0
    for a in range(n):
        for b in range(a+2,n):
            if a==0 and b==n-1:continue
            da[m]=a;db[m]=b;m+=1
    var boundary:UInt64=0
    for a in range(n):boundary=boundary|cee_edge_bit(a,(a+1)%n)
    var total=0
    for mask in range(1<<m):
        var count=0
        for i in range(m):
            if (mask>>i)&1!=0:count+=1
        if count!=n-3:continue
        var crossing=False
        for i in range(m):
            if crossing:break
            if (mask>>i)&1==0:continue
            for j in range(i+1,m):
                if (mask>>j)&1!=0 and cee_crosses(p,da[i],db[i],da[j],db[j]):crossing=True;break
        if crossing:continue
        var edges=boundary
        for i in range(m):
            if (mask>>i)&1!=0:edges=edges|cee_edge_bit(da[i],db[i])
        var faces=InlineArray[CeeTriangle,CEE_MAX_TRI](fill=CeeTriangle(0,0,0));var nf=0
        for a in range(n):
            for b in range(a+1,n):
                for c in range(b+1,n):
                    if (edges&cee_edge_bit(a,b))==0 or (edges&cee_edge_bit(b,c))==0 or (edges&cee_edge_bit(c,a))==0:continue
                    var contains=False
                    for v in range(n):
                        if v!=a and v!=b and v!=c and cee_inside(p,CeeTriangle(a,b,c),v):contains=True;break
                    if not contains and nf<CEE_MAX_TRI:faces[nf]=CeeTriangle(a,b,c);nf+=1
        if nf==n-2 and total<CEE_MAX_ALL:out[total]=CeeTriangulation(faces,nf,edges);total+=1
    total

fn cee_rank(p:InlineArray[CeePoint,CEE_MAX_N],n:Int,target:CeeFraction)->Int64:
    var seen=InlineArray[CeeFraction,CEE_MAX_TRIPLES](fill=CeeFraction(0,1));var count=0
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                var sides=InlineArray[Int64,3](fill=0);let score=cee_score(p,CeeTriangle(a,b,c),sides)
                if cee_compare(score,target)>=0:continue
                var duplicate=False
                for i in range(count):
                    if cee_compare(score,seen[i])==0:duplicate=True;break
                if not duplicate:seen[count]=score;count+=1
    Int64(count+1)

fn cee_solve(p:InlineArray[CeePoint,CEE_MAX_N],n:Int)->Int64:
    var all=InlineArray[CeeTriangulation,CEE_MAX_ALL](fill=CeeTriangulation(InlineArray[CeeTriangle,CEE_MAX_TRI](fill=CeeTriangle(0,0,0)),0,0))
    let total=cee_enumerate(p,n,all)
    var fan=CeeTriangulation(InlineArray[CeeTriangle,CEE_MAX_TRI](fill=CeeTriangle(0,0,0)),0,0)
    for k in range(1,n-1):fan.triangles[fan.count]=CeeTriangle(0,k,k+1);fan.count+=1
    for a in range(n):fan.edges=fan.edges|cee_edge_bit(a,(a+1)%n)
    for k in range(2,n-1):fan.edges=fan.edges|cee_edge_bit(0,k)
    var index=-1
    for i in range(total):
        if all[i].edges==fan.edges:index=i;break
    if index<0:return -1
    var current=all[index];var cm=cee_evaluate(p,n,current)
    for step in range(CEE_MAX_ALL):
        var changed=False
        for ti in range(current.count):
            if changed:break
            let t=current.triangles[ti];var sides=InlineArray[Int64,3](fill=0);let score=cee_score(p,t,sides)
            if cee_compare(score,cm.maximum)!=0 or score.num==0:continue
            var largest=0
            if sides[1]>sides[largest]:largest=1
            if sides[2]>sides[largest]:largest=2
            let vertices=InlineArray[Int,3](t.a,t.b,t.c)
            for ap in range(3):
                if changed:break
                if sides[ap]!=sides[largest]:continue
                let q=vertices[ap];var opposite=InlineArray[Int,2](fill=0);var used=0
                for k in range(3):
                    if k!=ap:opposite[used]=vertices[k];used+=1
                for s in range(n):
                    if changed:break
                    let added=cee_edge_bit(q,s)
                    if s==q or (current.edges&added)!=0 or not cee_crosses(p,q,s,opposite[0],opposite[1]):continue
                    var retained=current.edges
                    for u in range(n):
                        for v in range(u+1,n):
                            let bit=cee_edge_bit(u,v)
                            if (retained&bit)!=0 and cee_crosses(p,q,s,u,v):retained=retained&(~bit)
                    var selected=-1;var sm=CeeMetrics(CeeFraction(0,1),0)
                    for ci in range(total):
                        if (all[ci].edges&added)==0 or (all[ci].edges&retained)!=retained:continue
                        let candidate=cee_evaluate(p,n,all[ci])
                        if not cee_improves(candidate,cm):continue
                        if selected<0 or cee_preferable(candidate,sm):selected=ci;sm=candidate
                    if selected>=0:current=all[selected];cm=sm;changed=True
        if not changed:break
    cee_rank(p,n,cm.maximum)

fn cee_impl(input:UnsafePointer[Int64,ImmutAnyOrigin],length:Int)->Int64:
    if length<1 or length>CEE_MAX_LEN:return -1
    if input[0]<3 or input[0]>CEE_MAX_N:return -1
    let n=Int(input[0]);if length!=1+2*n:return -1
    var p=InlineArray[CeePoint,CEE_MAX_N](fill=CeePoint(0,0))
    for i in range(n):
        p[i]=CeePoint(input[1+2*i],input[2+2*i])
        if p[i].x < -4 or p[i].x>4 or p[i].y < -4 or p[i].y>4:return -1
        for j in range(i):
            if p[j].x==p[i].x and p[j].y==p[i].y:return -1
    var area:Int64=0
    for i in range(n):
        let next=(i+1)%n;area+=p[i].x*p[next].y-p[i].y*p[next].x
    if area==0:return -1
    let direction:Int64=1 if area>0 else -1
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                if cee_orient(p[a],p[b],p[c])==0:return -1
    for e in range(n):
        let next=(e+1)%n
        for v in range(n):
            if v!=e and v!=next and direction*cee_orient(p[e],p[next],p[v])<=0:return -1
    cee_solve(p,n)

@export("convex_polygon_minimax_eccentricity_edge_insertion")
fn convex_polygon_minimax_eccentricity_edge_insertion(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length>c_size_t(CEE_MAX_LEN):return -1
    cee_impl(input,Int(length))
