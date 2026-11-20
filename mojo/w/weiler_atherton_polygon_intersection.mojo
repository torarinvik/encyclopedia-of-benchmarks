from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime WA_V = 6
comptime WA_X = 36
comptime WA_NODE = 42
comptime WA_WORDS = 210
comptime WA_OUTPUT = 1680

@fieldwise_init
struct WaRat(Copyable):
    var n: Int64
    var d: Int64

@fieldwise_init
struct WaPoint(Copyable):
    var xn: Int64
    var xd: Int64
    var yn: Int64
    var yd: Int64

@fieldwise_init
struct WaCrossing(Copyable):
    var p: WaPoint
    var ta: WaRat
    var tb: WaRat
    var ae: Bool
    var ax: Bool
    var be: Bool
    var bx: Bool

@fieldwise_init
struct WaNode(Copyable):
    var p: WaPoint
    var crossing: Int

@fieldwise_init
struct WaEvent(Copyable):
    var t: WaRat
    var id: Int

fn wa_gcd(a0: Int64, b0: Int64) -> Int64:
    var a = -a0 if a0 < 0 else a0
    var b = -b0 if b0 < 0 else b0
    while b != 0:
        let r = a % b
        a = b
        b = r
    if a == 0: return 1
    return a

fn wa_rat(n0: Int64, d0: Int64) -> WaRat:
    var n = n0
    var d = d0
    if d < 0: n = -n; d = -d
    let g = wa_gcd(n, d)
    WaRat(n // g, d // g)

fn wa_less_rat(a: WaRat, b: WaRat) -> Bool: a.n * b.d < b.n * a.d
fn wa_equal_rat(a: WaRat, b: WaRat) -> Bool: a.n == b.n and a.d == b.d
fn wa_less_point(a: WaPoint, b: WaPoint) -> Bool:
    if a.xn * b.xd != b.xn * a.xd: return a.xn * b.xd < b.xn * a.xd
    a.yn * b.yd < b.yn * a.yd
fn wa_equal_point(a: WaPoint, b: WaPoint) -> Bool:
    wa_equal_rat(WaRat(a.xn,a.xd),WaRat(b.xn,b.xd)) and wa_equal_rat(WaRat(a.yn,a.yd),WaRat(b.yn,b.yd))
fn wa_ip(x: Int64, y: Int64) -> WaPoint: WaPoint(x,1,y,1)
fn wa_orient(ax:Int64,ay:Int64,bx:Int64,by:Int64,cx:Int64,cy:Int64)->Int64:
    (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
fn wa_on(ax:Int64,ay:Int64,bx:Int64,by:Int64,px:Int64,py:Int64)->Bool:
    wa_orient(ax,ay,bx,by,px,py)==0 and px>=min(ax,bx) and px<=max(ax,bx) and py>=min(ay,by) and py<=max(ay,by)
fn wa_relation(ax:Int64,ay:Int64,bx:Int64,by:Int64,cx:Int64,cy:Int64,dx:Int64,dy:Int64)->Int:
    let o1=wa_orient(ax,ay,bx,by,cx,cy);let o2=wa_orient(ax,ay,bx,by,dx,dy)
    let o3=wa_orient(cx,cy,dx,dy,ax,ay);let o4=wa_orient(cx,cy,dx,dy,bx,by)
    if ((o1>0 and o2<0) or (o1<0 and o2>0)) and ((o3>0 and o4<0) or (o3<0 and o4>0)): return 1
    if (o1==0 and wa_on(ax,ay,bx,by,cx,cy)) or (o2==0 and wa_on(ax,ay,bx,by,dx,dy)) or (o3==0 and wa_on(cx,cy,dx,dy,ax,ay)) or (o4==0 and wa_on(cx,cy,dx,dy,bx,by)): return 2
    0
fn wa_valid(p: InlineArray[Int64,12], n:Int)->Bool:
    var area:Int64=0
    for i in range(n):
        let prev=(i+n-1)%n;let next=(i+1)%n
        area+=p[2*i]*p[2*next+1]-p[2*i+1]*p[2*next]
        if wa_orient(p[2*prev],p[2*prev+1],p[2*i],p[2*i+1],p[2*next],p[2*next+1])==0:return False
        for j in range(i):
            if p[2*i]==p[2*j] and p[2*i+1]==p[2*j+1]:return False
    if area<=0:return False
    for i in range(n):
        for j in range(i+1,n):
            if j==i+1 or (i==0 and j==n-1):continue
            let k=(i+1)%n;let l=(j+1)%n
            if wa_relation(p[2*i],p[2*i+1],p[2*k],p[2*k+1],p[2*j],p[2*j+1],p[2*l],p[2*l+1])!=0:return False
    True
fn wa_inside(x:Int64,y:Int64,p:InlineArray[Int64,12],n:Int)->Bool:
    var winding=0
    for i in range(n):
        let j=(i+1)%n;let side=wa_orient(p[2*i],p[2*i+1],p[2*j],p[2*j+1],x,y)
        if p[2*i+1]<=y and y<p[2*j+1] and side>0:winding+=1
        elif p[2*j+1]<=y and y<p[2*i+1] and side<0:winding-=1
    winding!=0
fn wa_cross_point(ax:Int64,ay:Int64,bx:Int64,by:Int64,cx:Int64,cy:Int64,dx:Int64,dy:Int64)->(WaRat,WaRat,WaPoint):
    let rx=bx-ax;let ry=by-ay;let sx=dx-cx;let sy=dy-cy
    var den=rx*sy-ry*sx;var tn=(cx-ax)*sy-(cy-ay)*sx;var un=(cx-ax)*ry-(cy-ay)*rx
    if den<0:den=-den;tn=-tn;un=-un
    let ta=wa_rat(tn,den);let tb=wa_rat(un,den)
    let x=wa_rat(ax*den+rx*tn,den);let y=wa_rat(ay*den+ry*tn,den)
    (ta,tb,WaPoint(x.n,x.d,y.n,y.d))
fn wa_store(out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=UInt64(value)
    for byte in range(8):out[offset+byte]=UInt8((bits>>UInt(8*byte))&255)

fn wa_impl(input:UnsafePointer[Int64,ImmutAnyOrigin],length:Int,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t)->Int64:
    if length<2 or length>27:return -1
    let na0=input[0];let nb0=input[1]
    if na0<3 or na0>6 or nb0<3 or nb0>6:return -1
    let na=Int(na0);let nb=Int(nb0)
    if length!=2+2*na+2*nb:return -1
    var a=InlineArray[Int64,12](fill=0);var b=InlineArray[Int64,12](fill=0);var at=2
    for i in range(2*na):
        let v=input[at];at+=1
        if v < -16 or v>16:return -1
        a[i]=v
    for i in range(2*nb):
        let v=input[at];at+=1
        if v < -16 or v>16:return -1
        b[i]=v
    if not wa_valid(a,na) or not wa_valid(b,nb):return -1
    var crosses=InlineArray[WaCrossing,WA_X](fill=WaCrossing(wa_ip(0,0),WaRat(0,1),WaRat(0,1),False,False,False,False))
    var ea=InlineArray[WaEvent,WA_X](fill=WaEvent(WaRat(0,1),0));var eb=InlineArray[WaEvent,WA_X](fill=WaEvent(WaRat(0,1),0))
    var ca=InlineArray[Int,WA_V](fill=0);var cb=InlineArray[Int,WA_V](fill=0);var xc=0
    for i in range(na):
        for j in range(nb):
            let ai=(i+1)%na;let bj=(j+1)%nb
            let rel=wa_relation(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1],b[2*bj],b[2*bj+1])
            if rel==2:return -1
            if rel==1:
                let (ta,tb,p)=wa_cross_point(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1],b[2*bj],b[2*bj+1])
                let ab=wa_orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*i],a[2*i+1]);let aa=wa_orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*ai],a[2*ai+1])
                let bb=wa_orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1]);let ba=wa_orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*bj],b[2*bj+1])
                let c=WaCrossing(p,ta,tb,ab<0 and aa>0,ab>0 and aa<0,bb<0 and ba>0,bb>0 and ba<0)
                if (not c.ae and not c.ax) or (not c.be and not c.bx) or c.ae==c.be:return -1
                crosses[xc]=c;ea[i*WA_V+ca[i]]=WaEvent(ta,xc);eb[j*WA_V+cb[j]]=WaEvent(tb,xc);ca[i]+=1;cb[j]+=1;xc+=1
    var rings=InlineArray[InlineArray[WaPoint,48],16](fill=InlineArray[WaPoint,48](fill=wa_ip(0,0)))
    var sizes=InlineArray[Int,16](fill=0);var rc=0
    if xc==0:
        if wa_inside(a[0],a[1],b,nb):
            for i in range(na):rings[0][i]=wa_ip(a[2*i],a[2*i+1])
            sizes[0]=na;rc=1
        elif wa_inside(b[0],b[1],a,na):
            for i in range(nb):rings[0][i]=wa_ip(b[2*i],b[2*i+1])
            sizes[0]=nb;rc=1
    else:
        var nodes_a=InlineArray[WaNode,WA_NODE](fill=WaNode(wa_ip(0,0),-1));var nodes_b=InlineArray[WaNode,WA_NODE](fill=WaNode(wa_ip(0,0),-1))
        var pos_a=InlineArray[Int,WA_X](fill=0);var pos_b=InlineArray[Int,WA_X](fill=0);var nca=0;var ncb=0
        for e in range(na):
            nodes_a[nca]=WaNode(wa_ip(a[2*e],a[2*e+1]),-1);nca+=1
            for z in range(1,ca[e]):
                let id=ea[e*WA_V+z].id;var k=z
                while k>0:
                    let prior=ea[e*WA_V+k-1].id
                    if not wa_less_rat(crosses[id].ta,crosses[prior].ta):break
                    ea[e*WA_V+k]=ea[e*WA_V+k-1];k-=1
                ea[e*WA_V+k]=WaEvent(crosses[id].ta,id)
            for z in range(ca[e]):let id=ea[e*WA_V+z].id;nodes_a[nca]=WaNode(crosses[id].p,id);pos_a[id]=nca;nca+=1
        for e in range(nb):
            nodes_b[ncb]=WaNode(wa_ip(b[2*e],b[2*e+1]),-1);ncb+=1
            for z in range(1,cb[e]):
                let id=eb[e*WA_V+z].id;var k=z
                while k>0:
                    let prior=eb[e*WA_V+k-1].id
                    if not wa_less_rat(crosses[id].tb,crosses[prior].tb):break
                    eb[e*WA_V+k]=eb[e*WA_V+k-1];k-=1
                eb[e*WA_V+k]=WaEvent(crosses[id].tb,id)
            for z in range(cb[e]):let id=eb[e*WA_V+z].id;nodes_b[ncb]=WaNode(crosses[id].p,id);pos_b[id]=ncb;ncb+=1
        var visited=InlineArray[Bool,WA_X](fill=False)
        for start in range(nca):
            let sid=nodes_a[start].crossing
            if sid<0 or not crosses[sid].ae or visited[sid]:continue
            if rc>=16:return -1
            var ring=InlineArray[WaPoint,48](fill=wa_ip(0,0));var count=1;ring[0]=nodes_a[start].p;visited[sid]=True
            var active_a=True;var index=start;var guard=0
            while True:
                guard+=1
                if guard>2*xc+na+nb+1:return -1
                let nc=if active_a:nca else:ncb;let next=(index+1)%nc;let node=if active_a:nodes_a[next] else:nodes_b[next]
                if node.crossing>=0:
                    let id=node.crossing;visited[id]=True
                    if active_a and id==sid:break
                    let exits=if active_a:crosses[id].ax else:crosses[id].bx
                    if exits:
                        if id==sid:break
                        active_a=not active_a;index=if active_a:pos_a[id] else:pos_b[id];continue
                if count>=48:return -1
                ring[count]=node.p;count+=1
                index=next
            if count<3:return -1
            for i in range(count):rings[rc][i]=ring[i]
            sizes[rc]=count;rc+=1
        for id in range(xc):if not visited[id]:return -1
    # Canonicalize each ring by its lexicographically least rational point.
    for r in range(rc):
        var pivot=0
        for i in range(1,sizes[r]):if wa_less_point(rings[r][i],rings[r][pivot]):pivot=i
        if pivot>0:
            var tmp=InlineArray[WaPoint,48](fill=wa_ip(0,0))
            for i in range(sizes[r]):tmp[i]=rings[r][(pivot+i)%sizes[r]]
            for i in range(sizes[r]):rings[r][i]=tmp[i]
    for i in range(1,rc):
        let key=rings[i];let key_n=sizes[i];var j=i
        while j>0 and wa_less_point(key[0],rings[j-1][0]):rings[j]=rings[j-1];sizes[j]=sizes[j-1];j-=1
        rings[j]=key;sizes[j]=key_n
    var words=InlineArray[Int64,WA_WORDS](fill=0);var wc=0;words[wc]=Int64(rc);wc+=1
    for r in range(rc):
        words[wc]=Int64(sizes[r]);wc+=1
        for i in range(sizes[r]):let p=rings[r][i];words[wc]=p.xn;words[wc+1]=p.xd;words[wc+2]=p.yn;words[wc+3]=p.yd;wc+=4
    let needed=wc*8
    if needed>WA_OUTPUT:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
    for i in range(wc):wa_store(output,8*i,words[i])
    Int64(needed)

@export("weiler_atherton_polygon_intersection")
fn weiler_atherton_polygon_intersection(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
    output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length>c_size_t(27):return -1
    wa_impl(input,Int(length),output,capacity)
