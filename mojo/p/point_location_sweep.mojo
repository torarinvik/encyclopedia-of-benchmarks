# Offline point location by sweeping edge endpoints and query x-coordinates.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@fieldwise_init
struct Point(Copyable):
    var x: Int64
    var y: Int64

@fieldwise_init
struct Edge(Copyable):
    var u: Int
    var v: Int
    var face: Int

@fieldwise_init
struct Event(Copyable):
    var x: Int64
    var kind: Int
    var id: Int

fn pl_cross(a: Point, b: Point, c: Point) -> Int64:
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x)

fn pl_on_segment(a: Point,b: Point,p: Point)->Bool:
    return pl_cross(a,b,p)==0 and p.x>=min(a.x,b.x) and p.x<=max(a.x,b.x) and p.y>=min(a.y,b.y) and p.y<=max(a.y,b.y)

fn pl_intersects(a:Point,b:Point,c:Point,d:Point)->Bool:
    let o1=pl_cross(a,b,c);let o2=pl_cross(a,b,d);let o3=pl_cross(c,d,a);let o4=pl_cross(c,d,b)
    if o1==0 and pl_on_segment(a,b,c):return True
    if o2==0 and pl_on_segment(a,b,d):return True
    if o3==0 and pl_on_segment(c,d,a):return True
    if o4==0 and pl_on_segment(c,d,b):return True
    return ((o1<0 and o2>0) or (o1>0 and o2<0)) and ((o3<0 and o4>0) or (o3>0 and o4<0))

fn pl_left(points:InlineArray[Point,16],edge:Edge)->Int:
    return edge.u if points[edge.u].x<points[edge.v].x else edge.v
fn pl_right(points:InlineArray[Point,16],edge:Edge)->Int:
    return edge.v if points[edge.u].x<points[edge.v].x else edge.u
fn pl_height_num(points:InlineArray[Point,16],edge:Edge,x:Int64,inout den:Int64)->Int64:
    let left=pl_left(points,edge);let right=pl_right(points,edge);den=points[right].x-points[left].x
    return points[left].y*den+(points[right].y-points[left].y)*(x-points[left].x)
fn pl_edge_less(points:InlineArray[Point,16],edges:InlineArray[Edge,24],first:Int,second:Int,x:Int64)->Bool:
    var d1:Int64=0;var d2:Int64=0;let n1=pl_height_num(points,edges[first],x,d1);let n2=pl_height_num(points,edges[second],x,d2)
    if n1*d2!=n2*d1:return n1*d2<n2*d1
    let l1=pl_left(points,edges[first]);let r1=pl_right(points,edges[first]);let l2=pl_left(points,edges[second]);let r2=pl_right(points,edges[second])
    let s1=(points[r1].y-points[l1].y)*(points[r2].x-points[l2].x);let s2=(points[r2].y-points[l2].y)*(points[r1].x-points[l1].x)
    return s1<s2 if s1!=s2 else first<second
fn pl_event_less(a:Event,b:Event)->Bool:
    if a.x!=b.x:return a.x<b.x
    if a.kind!=b.kind:return a.kind<b.kind
    return a.id<b.id
fn pl_query(points:InlineArray[Point,16],edges:InlineArray[Edge,24],active:InlineArray[Int,24],count:Int,x:Int64,y:Int64,faces:Int)->Int64:
    var low=0;var high=count
    while low<high:
        let middle=low+(high-low)//2;var den:Int64=0;let num=pl_height_num(points,edges[active[middle]],x,den)
        if num<y*den:low=middle+1
        else:high=middle
    if low<count:
        var den:Int64=0;let num=pl_height_num(points,edges[active[low]],x,den)
        if num==y*den:return Int64(faces+active[low]+1)
    if low==0:return 0
    let face=edges[active[low-1]].face
    return Int64(face+1) if face>=0 else 0

@export("point_location_sweep")
fn point_location_sweep(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>141:return -1
    let nr=input[0];let mr=input[1];let qr=input[2];let fr=input[3]
    if nr<2 or nr>16 or mr<1 or mr>24 or qr<0 or qr>16 or fr<1 or fr>16:return -1
    let n=Int(nr);let m=Int(mr);let q=Int(qr);let faces=Int(fr)
    if length!=c_size_t(4+2*n+3*m+2*q):return -1
    var points=InlineArray[Point,16](fill=Point(x=0,y=0));var edges=InlineArray[Edge,24](fill=Edge(u=0,v=0,face=0));var queries=InlineArray[Point,16](fill=Point(x=0,y=0))
    var cursor=4
    for i in range(n):
        points[i]=Point(x=input[cursor],y=input[cursor+1]);cursor+=2
        if points[i].x< -300 or points[i].x>300 or points[i].y< -300 or points[i].y>300:return -1
        for j in range(i):
            if points[j].x==points[i].x:return -1
    for i in range(m):
        let ur=input[cursor];let vr=input[cursor+1];let frv=input[cursor+2];cursor+=3
        if ur<0 or ur>=nr or vr<0 or vr>=nr or ur==vr or frv< -1 or frv>=fr:return -1
        edges[i]=Edge(u=Int(ur),v=Int(vr),face=Int(frv))
        for j in range(i):
            if (edges[j].u==edges[i].u and edges[j].v==edges[i].v) or (edges[j].u==edges[i].v and edges[j].v==edges[i].u):return -1
            let su=edges[j].u==edges[i].u or edges[j].u==edges[i].v;let sv=edges[j].v==edges[i].u or edges[j].v==edges[i].v
            if su or sv:
                let common=edges[j].u if su else edges[j].v;let oa=edges[i].v if edges[i].u==common else edges[i].u;let ob=edges[j].v if edges[j].u==common else edges[j].u
                if pl_cross(points[common],points[oa],points[ob])==0:return -1
            elif pl_intersects(points[edges[i].u],points[edges[i].v],points[edges[j].u],points[edges[j].v]):return -1
    for i in range(q):
        queries[i]=Point(x=input[cursor],y=input[cursor+1]);cursor+=2
        if queries[i].x< -300 or queries[i].x>300 or queries[i].y< -300 or queries[i].y>300:return -1
        for j in range(n):
            if queries[i].x==points[j].x:return -1
    var events=InlineArray[Event,64](fill=Event(x=0,kind=0,id=0));var event_count=0
    for i in range(m):
        let left=pl_left(points,edges[i]);let right=pl_right(points,edges[i])
        events[event_count]=Event(x=points[left].x,kind=1,id=i);event_count+=1
        events[event_count]=Event(x=points[right].x,kind=0,id=i);event_count+=1
    for i in range(q):events[event_count]=Event(x=queries[i].x,kind=2,id=i);event_count+=1
    for i in range(1,event_count):
        let key=events[i];var j=i
        while j>0 and pl_event_less(key,events[j-1]):events[j]=events[j-1];j-=1
        events[j]=key
    var active=InlineArray[Int,24](fill=0);var active_count=0;var answers=InlineArray[Int64,16](fill=0)
    for event_index in range(event_count):
        let event=events[event_index]
        if event.kind==0:
            var position=0
            while position<active_count and active[position]!=event.id:position+=1
            if position==active_count:return -1
            for k in range(position+1,active_count):active[k-1]=active[k]
            active_count-=1
        elif event.kind==1:
            var low=0;var high=active_count
            while low<high:
                let middle=low+(high-low)//2
                if pl_edge_less(points,edges,active[middle],event.id,event.x):low=middle+1
                else:high=middle
            var j=active_count
            while j>low:active[j]=active[j-1];j-=1
            active[low]=event.id;active_count+=1
        else:answers[event.id]=pl_query(points,edges,active,active_count,event.x,queries[event.id].y,faces)
    var result:Int64=0
    for i in range(q):result+=Int64(i+1)*answers[i]
    return result
