from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn tsw_cross(ax:Int64,ay:Int64,bx:Int64,by:Int64,px:Int64,py:Int64)->Int64:
    return (bx-ax)*(py-ay)-(by-ay)*(px-ax)
fn tsw_same(a:Int,b:Int,c:Int,d:Int)->Bool:
    return (a==c and b==d) or (a==d and b==c)
fn tsw_on(ax:Int64,ay:Int64,bx:Int64,by:Int64,px:Int64,py:Int64)->Bool:
    return tsw_cross(ax,ay,bx,by,px,py)==0 and px>=min(ax,bx) and px<=max(ax,bx) and py>=min(ay,by) and py<=max(ay,by)
fn tsw_intersect(ax:Int64,ay:Int64,bx:Int64,by:Int64,cx:Int64,cy:Int64,dx:Int64,dy:Int64)->Bool:
    let o1=tsw_cross(ax,ay,bx,by,cx,cy);let o2=tsw_cross(ax,ay,bx,by,dx,dy)
    let o3=tsw_cross(cx,cy,dx,dy,ax,ay);let o4=tsw_cross(cx,cy,dx,dy,bx,by)
    if (o1==0 and tsw_on(ax,ay,bx,by,cx,cy)) or (o2==0 and tsw_on(ax,ay,bx,by,dx,dy)) or (o3==0 and tsw_on(cx,cy,dx,dy,ax,ay)) or (o4==0 and tsw_on(cx,cy,dx,dy,bx,by)):
        return True
    return ((o1<0 and o2>0) or (o1>0 and o2<0)) and ((o3<0 and o4>0) or (o3>0 and o4<0))

@export("triangulation_stochastic_visibility_walk")
fn triangulation_stochastic_visibility_walk(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<8 or length>57:return -1
    let vr=input[0];let br=input[1];let tr=input[2];let sr=input[3]
    let px=input[4];let py=input[5];let capr=input[6];let kr=input[7]
    if vr<3 or vr>6 or br<3 or br>vr or tr!=2*vr-br-2 or tr<1 or tr>7 or sr<0 or sr>=tr or capr<0 or capr>12 or kr<0 or kr>12 or px< -200 or px>200 or py< -200 or py>200:return -1
    let v=Int(vr);let bcount=Int(br);let tcount=Int(tr);let start=Int(sr);let cap=Int(capr);let k=Int(kr)
    if length!=c_size_t(8+2*v+bcount+3*tcount+k):return -1
    var xs=InlineArray[Int64,6](fill=0);var ys=InlineArray[Int64,6](fill=0)
    var boundary=InlineArray[Int,6](fill=0);var faces=InlineArray[Int,21](fill=0);var neighbors=InlineArray[Int,21](fill=-1);var used=InlineArray[Bool,6](fill=False)
    var cursor=8
    for i in range(v):
        xs[i]=input[cursor];ys[i]=input[cursor+1];cursor+=2
        if xs[i]< -200 or xs[i]>200 or ys[i]< -200 or ys[i]>200:return -1
        for j in range(i):
            if xs[i]==xs[j] and ys[i]==ys[j]:return -1
    for i in range(bcount):
        let raw=input[cursor];cursor+=1
        if raw<0 or raw>=vr:return -1
        boundary[i]=Int(raw)
        for j in range(i):
            if boundary[i]==boundary[j]:return -1
    for i in range(bcount):
        let a=boundary[i];let b=boundary[(i+1)%bcount]
        for j in range(bcount):
            let c=boundary[j]
            if c!=a and c!=b and tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0:return -1
    for p in range(v):
        var on_boundary=False
        for j in range(bcount):
            if boundary[j]==p:on_boundary=True
        if not on_boundary:
            for j in range(bcount):
                let a=boundary[j];let b=boundary[(j+1)%bcount]
                if tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p])<=0:return -1
    var area_sum:Int64=0
    for f in range(tcount):
        for e in range(3):
            let raw=input[cursor];cursor+=1
            if raw<0 or raw>=vr:return -1
            faces[f*3+e]=Int(raw)
        let a=faces[f*3];let b=faces[f*3+1];let c=faces[f*3+2]
        if a==b or b==c or c==a or tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0:return -1
        used[a]=True;used[b]=True;used[c]=True
        area_sum+=tsw_cross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])
        for g in range(f):
            var same=True
            for e in range(3):
                var found=False
                for j in range(3):
                    if faces[f*3+e]==faces[g*3+j]:found=True
                if not found:same=False
            if same:return -1
    for i in range(v):
        if not used[i]:return -1
    var polygon_area:Int64=0
    for i in range(bcount):
        let a=boundary[i];let b=boundary[(i+1)%bcount]
        polygon_area+=xs[a]*ys[b]-ys[a]*xs[b]
    if polygon_area<=0 or polygon_area!=area_sum:return -1
    for i in range(bcount):
        let a=boundary[i];let b=boundary[(i+1)%bcount];var owners=0
        for f in range(tcount):
            for e in range(3):
                if tsw_same(a,b,faces[f*3+e],faces[f*3+(e+1)%3]):owners+=1
        if owners!=1:return -1
    for f in range(tcount):
        for e in range(3):
            let a=faces[f*3+e];let b=faces[f*3+(e+1)%3]
            var first=True
            for g in range(f+1):
                for ge in range(3):
                    if g==f and ge>=e:continue
                    if tsw_same(a,b,faces[g*3+ge],faces[g*3+(ge+1)%3]):first=False
            if first:
                for p in range(v):
                    if p!=a and p!=b and tsw_on(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p]):return -1
                for g in range(f,tcount):
                    for ge in range(3):
                        if g==f and ge<=e:continue
                        let c=faces[g*3+ge];let d=faces[g*3+(ge+1)%3]
                        if a==c or a==d or b==c or b==d:continue
                        if tsw_intersect(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c],xs[d],ys[d]):return -1
    for f in range(tcount):
        for e in range(3):
            let a=faces[f*3+e];let b=faces[f*3+(e+1)%3]
            var boundary_edge=False
            for i in range(bcount):
                if tsw_same(a,b,boundary[i],boundary[(i+1)%bcount]):boundary_edge=True
            var owners=0;var other=-1;var first_u=-1;var first_v=-1
            for g in range(tcount):
                for ge in range(3):
                    if tsw_same(a,b,faces[g*3+ge],faces[g*3+(ge+1)%3]):
                        if owners==0:first_u=faces[g*3+ge];first_v=faces[g*3+(ge+1)%3]
                        elif faces[g*3+ge]!=first_v or faces[g*3+(ge+1)%3]!=first_u:return -1
                        owners+=1
                        if g!=f:other=g
            let expected_owners=1 if boundary_edge else 2
            if owners!=expected_owners:return -1
            if not boundary_edge:neighbors[f*3+e]=other
    for i in range(k):
        if input[cursor+i]<0 or input[cursor+i]>1:return -1
    for i in range(bcount):
        let a=boundary[i];let b=boundary[(i+1)%bcount]
        if tsw_cross(xs[a],ys[a],xs[b],ys[b],px,py)<=0:return -1
    var containing=0
    for f in range(tcount):
        let a=faces[f*3];let b=faces[f*3+1];let c=faces[f*3+2]
        if tsw_cross(xs[a],ys[a],xs[b],ys[b],px,py)>0 and tsw_cross(xs[b],ys[b],xs[c],ys[c],px,py)>0 and tsw_cross(xs[c],ys[c],xs[a],ys[a],px,py)>0:containing+=1
    if containing!=1:return -1
    var face=start;var steps=0;var choice_index=0;var trace:Int64=Int64(face+1);var predicates:Int64=0;var status=0
    while True:
        let a=faces[face*3];let b=faces[face*3+1];let c=faces[face*3+2]
        var eu=InlineArray[Int,3](fill=0);var ev=InlineArray[Int,3](fill=0)
        eu[0]=a;eu[1]=b;eu[2]=c;ev[0]=b;ev[1]=c;ev[2]=a
        var eligible=InlineArray[Int,3](fill=0);var count=0
        for e in range(3):
            predicates+=1
            if tsw_cross(xs[eu[e]],ys[eu[e]],xs[ev[e]],ys[ev[e]],px,py)<0:eligible[count]=e;count+=1
        if count==0:status=0;break
        if steps==cap:status=2;break
        var selected=0
        if count==1:selected=eligible[0]
        elif count==2:
            if choice_index==k:status=1;break
            selected=eligible[Int(input[cursor+choice_index])];choice_index+=1
        else:return -1
        face=neighbors[face*3+selected]
        if face<0:return -1
        steps+=1;trace=trace*9+face+1
    return (trace*40+predicates)*3+status
