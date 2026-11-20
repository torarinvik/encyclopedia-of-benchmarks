# Delaunay-rooted reverse search over convex polygon triangulations.
from std.ffi import c_size_t
from std.collections import InlineArray
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("delaunay_rooted_triangulation_reverse_search")
fn delaunay_rooted_triangulation_reverse_search(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                                 length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 29: return -1
    let n64 = input[0]
    if n64 < 3 or n64 > 8 or length != c_size_t(4*n64-4): return -1
    let n = Int(n64)
    var points = InlineArray[Int64,16](fill=0)
    for i in range(n):
        let x=input[1+2*i]; let y=input[2+2*i]
        if x < -50 or x > 50 or y < -50 or y > 50: return -1
        points[2*i]=x; points[2*i+1]=y
    for a in range(n):
        for b in range(a+1,n):
            for z in range(b+1,n):
                if orient(points,a,b,z)<=0:return -1
    for a in range(n):
        for b in range(a+1,n):
            for z in range(b+1,n):
                for q in range(z+1,n):
                    if incircle(points,a,b,z,q)==0:return -1
    var diagonals=InlineArray[Int,20](fill=0);var d=0
    for u in range(n):
        for v in range(u+1,n):
            if not is_boundary(n,u,v):diagonals[d]=8*u+v;d+=1
    let at=1+2*n
    if input[at]!=Int64(n-3):return -1
    var root:UInt64=0;var previous_u= -1;var previous_v= -1
    for i in range(n-3):
        let u64=input[at+1+2*i];let v64=input[at+2+2*i]
        if u64<0 or u64>=v64 or v64>=n64:return -1
        let u=Int(u64);let v=Int(v64)
        if is_boundary(n,u,v) or (i>0 and (u<previous_u or (u==previous_u and v<=previous_v))):return -1
        let index=find_diagonal(diagonals,d,u,v)
        if index<0:return -1
        root |= UInt64(1)<<index
        previous_u=u;previous_v=v
    for i in range(d):
        if (root&(UInt64(1)<<i))!=0:
            for j in range(i+1,d):
                if (root&(UInt64(1)<<j))!=0 and crosses(diagonals[i],diagonals[j]):return -1
    if !valid_root(points,diagonals,n,d,root):return -1
    return reverse_search(points,diagonals,n,d,root)

fn orient(points:InlineArray[Int64,16],a:Int,b:Int,z:Int)->Int64:
    (points[2*b]-points[2*a])*(points[2*z+1]-points[2*a+1])-(points[2*b+1]-points[2*a+1])*(points[2*z]-points[2*a])

fn incircle(points:InlineArray[Int64,16],a:Int,b:Int,z:Int,d:Int)->Int64:
    let ax=points[2*a]-points[2*d];let ay=points[2*a+1]-points[2*d+1]
    let bx=points[2*b]-points[2*d];let by=points[2*b+1]-points[2*d+1]
    let cx=points[2*z]-points[2*d];let cy=points[2*z+1]-points[2*d+1]
    let al=ax*ax+ay*ay;let bl=bx*bx+by*by;let cl=cx*cx+cy*cy
    al*(bx*cy-by*cx)-bl*(ax*cy-ay*cx)+cl*(ax*by-ay*bx)

fn is_boundary(n:Int,u:Int,v:Int)->Bool:
    v==u+1 or (u==0 and v==n-1)

fn unpack(diagonals:InlineArray[Int,20],i:Int)->(Int,Int):
    (diagonals[i]//8,diagonals[i]%8)

fn find_diagonal(diagonals:InlineArray[Int,20],d:Int,u:Int,v:Int)->Int:
    for i in range(d):
        let pair=unpack(diagonals,i)
        if pair.0==u and pair.1==v:return i
    return -1

fn crosses(first:Int,second:Int)->Bool:
    let a=first//8;let b=first%8;let c=second//8;let d=second%8
    (a<c and c<b and b<d) or (c<a and a<d and d<b)

fn adjacency(diagonals:InlineArray[Int,20],n:Int,d:Int,mask:UInt64)->InlineArray[UInt64,8]:
    var rows=InlineArray[UInt64,8](fill=0)
    for u in range(n):
        let v=(u+1)%n
        rows[u]|=UInt64(1)<<v;rows[v]|=UInt64(1)<<u
    for i in range(d):
        if (mask&(UInt64(1)<<i))!=0:
            let e=unpack(diagonals,i)
            rows[e.0]|=UInt64(1)<<e.1;rows[e.1]|=UInt64(1)<<e.0
    return rows

fn triangle_count(diagonals:InlineArray[Int,20],n:Int,d:Int,mask:UInt64)->Int:
    let rows=adjacency(diagonals,n,d,mask)
    var count=0
    for a in range(n):
        for b in range(a+1,n):
            for z in range(b+1,n):
                if (rows[a]&(UInt64(1)<<b))!=0 and (rows[b]&(UInt64(1)<<z))!=0 and (rows[a]&(UInt64(1)<<z))!=0:count+=1
    return count

fn common_opposites(diagonals:InlineArray[Int,20],n:Int,d:Int,mask:UInt64,edge:Int)->(Int,Int):
    let rows=adjacency(diagonals,n,d,mask);let e=unpack(diagonals,edge);let common=rows[e.0]&rows[e.1]
    var inside= -1;var outside= -1;var found=0
    for w in range(n):
        if (common&(UInt64(1)<<w))!=0:
            if e.0<w and w<e.1:inside=w
            else:outside=w
            found+=1
    if found!=2 or inside<0 or outside<0:return (-1,-1)
    return (inside,outside)

fn flip_state(points:InlineArray[Int64,16],diagonals:InlineArray[Int,20],n:Int,d:Int,mask:UInt64,edge:Int,require_lawson:Bool)->Int64:
    let e=unpack(diagonals,edge);let opposite=common_opposites(diagonals,n,d,mask,edge)
    if opposite.0<0:return -1
    if require_lawson and incircle(points,e.0,opposite.0,e.1,opposite.1)<=0:return -1
    let lo=min(opposite.0,opposite.1);let hi=max(opposite.0,opposite.1)
    let other=find_diagonal(diagonals,d,lo,hi)
    if other<0:return -1
    return Int64((mask&~(UInt64(1)<<edge))|(UInt64(1)<<other))

fn parent_state(points:InlineArray[Int64,16],diagonals:InlineArray[Int,20],n:Int,d:Int,mask:UInt64)->Int64:
    for edge in range(d):
        if (mask&(UInt64(1)<<edge))!=0:
            let p=flip_state(points,diagonals,n,d,mask,edge,True)
            if p>=0:return p
    return -1

fn valid_root(points:InlineArray[Int64,16],diagonals:InlineArray[Int,20],n:Int,d:Int,mask:UInt64)->Bool:
    if triangle_count(diagonals,n,d,mask)!=n-2:return False
    let rows=adjacency(diagonals,n,d,mask)
    for a in range(n):
        for b in range(a+1,n):
            for z in range(b+1,n):
                if (rows[a]&(UInt64(1)<<b))!=0 and (rows[b]&(UInt64(1)<<z))!=0 and (rows[a]&(UInt64(1)<<z))!=0:
                    for q in range(n):
                        if q!=a and q!=b and q!=z and incircle(points,a,b,z,q)>0:return False
    return True

fn reverse_search(points:InlineArray[Int64,16],diagonals:InlineArray[Int,20],n:Int,d:Int,root:UInt64)->Int64:
    var states=InlineArray[UInt64,132](fill=0);var cursor=InlineArray[Int,132](fill=0)
    var top=0;var count=1;states[0]=root
    while top>=0:
        if cursor[top]>=d:
            if top==0:break
            top-=1
            continue
        let edge=cursor[top];cursor[top]+=1
        if (states[top]&(UInt64(1)<<edge))==0:continue
        let child=flip_state(points,diagonals,n,d,states[top],edge,False)
        if child<0 or parent_state(points,diagonals,n,d,UInt64(child))!=Int64(states[top]):continue
        if count>=132:return -1
        count+=1;top+=1;states[top]=UInt64(child);cursor[top]=0
    return Int64(count)
