# Bounded Fortune sweep and exact cell clipping draft.
# MIT provenance and copyright notice are retained in the package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@fieldwise_init
struct FortuneRat(Copyable):
    var numerator: Int64
    var denominator: Int64

@fieldwise_init
struct FortunePoint(Copyable):
    var x: FortuneRat
    var y: FortuneRat

fn fortune_gcd(a0: Int64, b0: Int64) -> Int64:
    var a=abs(a0); var b=abs(b0)
    while b!=0:
        let rem=a%b; a=b; b=rem
    return 1 if a==0 else a

fn fortune_rat(num: Int64, den: Int64) -> FortuneRat:
    var n=num; var d=den
    if d<0: n = -n; d = -d
    let g=fortune_gcd(n,d)
    return FortuneRat(n//g,d//g)

fn fortune_add(a: FortuneRat, b: FortuneRat) -> FortuneRat:
    let g=fortune_gcd(a.denominator,b.denominator)
    let ad=a.denominator//g; let bd=b.denominator//g
    return fortune_rat(a.numerator*bd+b.numerator*ad,ad*b.denominator)

fn fortune_sub(a: FortuneRat, b: FortuneRat) -> FortuneRat:
    let g=fortune_gcd(a.denominator,b.denominator)
    let ad=a.denominator//g; let bd=b.denominator//g
    return fortune_rat(a.numerator*bd-b.numerator*ad,ad*b.denominator)

fn fortune_mul(a: FortuneRat, b: FortuneRat) -> FortuneRat:
    let g1=fortune_gcd(a.numerator,b.denominator)
    let g2=fortune_gcd(b.numerator,a.denominator)
    return fortune_rat((a.numerator//g1)*(b.numerator//g2),
                       (a.denominator//g2)*(b.denominator//g1))

fn fortune_div(a: FortuneRat, b: FortuneRat) -> FortuneRat:
    let g1=fortune_gcd(a.numerator,b.numerator)
    let g2=fortune_gcd(b.denominator,a.denominator)
    return fortune_rat((a.numerator//g1)*(b.denominator//g2),
                       (a.denominator//g2)*(b.numerator//g1))

fn fortune_cmp(a: FortuneRat, b: FortuneRat) -> Int:
    let g=fortune_gcd(a.denominator,b.denominator)
    let left=a.numerator*(b.denominator//g); let right=b.numerator*(a.denominator//g)
    return -1 if left<right else (1 if left>right else 0)

fn fortune_equal(a: FortunePoint, b: FortunePoint) -> Bool:
    return fortune_cmp(a.x,b.x)==0 and fortune_cmp(a.y,b.y)==0

fn fortune_distance(p: FortunePoint, a: Int64, b: Int64, c: Int64) -> FortuneRat:
    return fortune_sub(fortune_add(fortune_mul(FortuneRat(a,1),p.x),
                                    fortune_mul(FortuneRat(b,1),p.y)),FortuneRat(c,1))

fn fortune_intersection(p: FortunePoint, q: FortunePoint,
                        dp: FortuneRat, dq: FortuneRat) -> FortunePoint:
    let t=fortune_div(dp,fortune_sub(dp,dq))
    return FortunePoint(fortune_add(p.x,fortune_mul(t,fortune_sub(q.x,p.x))),
                        fortune_add(p.y,fortune_mul(t,fortune_sub(q.y,p.y))))

fn fortune_push(mut points: InlineArray[FortunePoint,32], mut count: Int, point: FortunePoint) -> Bool:
    if count>0 and fortune_equal(points[count-1],point): return True
    if count>=32: return False
    points[count]=point; count+=1
    return True

fn fortune_clip(mut points: InlineArray[FortunePoint,32], count: Int,
                a: Int64, b: Int64, c: Int64) -> Int:
    if count==0: return 0
    let zero=FortuneRat(0,1)
    var next=InlineArray[FortunePoint,32](fill=FortunePoint(zero,zero))
    var size=0
    for i in range(count):
        let p=points[i]; let q=points[(i+1)%count]
        let dp=fortune_distance(p,a,b,c); let dq=fortune_distance(q,a,b,c)
        let inside_p=dp.numerator<=0; let inside_q=dq.numerator<=0
        if inside_p and inside_q:
            if not fortune_push(next,size,q): return -1
        elif inside_p and not inside_q:
            if not fortune_push(next,size,fortune_intersection(p,q,dp,dq)): return -1
        elif not inside_p and inside_q:
            if not fortune_push(next,size,fortune_intersection(p,q,dp,dq)): return -1
            if not fortune_push(next,size,q): return -1
    if size>1 and fortune_equal(next[0],next[size-1]): size-=1
    for i in range(size): points[i]=next[i]
    return size

fn fortune_breakpoint(px: Float64, py: Float64, qx: Float64, qy: Float64,
                       line: Float64) -> Float64:
    let p = py-line; let q = qy-line
    if abs(py-qy) < 1.0e-10: return (px+qx)*0.5
    let a = qy-py
    let b = -2.0*px*q + 2.0*qx*p
    let c = (px*px+py*py-line*line)*q - (qx*qx+qy*qy-line*line)*p
    var discriminant = b*b-4.0*a*c
    if discriminant < 0.0 and discriminant > -1.0e-10: discriminant = 0.0
    let root = sqrt(discriminant)
    let r1 = (-b-root)/(2.0*a); let r2 = (-b+root)/(2.0*a)
    return max(r1,r2) if py<qy else min(r1,r2)

fn fortune_circle(x: InlineArray[Float64, 8], y: InlineArray[Float64, 8],
                  a: Int, b: Int, c: Int, line: Float64) -> (Bool, Float64):
    let cross = (x[b]-x[a])*(y[c]-y[a]) - (y[b]-y[a])*(x[c]-x[a])
    if cross >= 0.0: return (False, 0.0)
    let aa=x[a]*x[a]+y[a]*y[a]; let bb=x[b]*x[b]+y[b]*y[b]
    let cc=x[c]*x[c]+y[c]*y[c]
    let divisor=2.0*(x[a]*(y[b]-y[c])+x[b]*(y[c]-y[a])+x[c]*(y[a]-y[b]))
    if abs(divisor)<1.0e-10: return (False, 0.0)
    let cx=(aa*(y[b]-y[c])+bb*(y[c]-y[a])+cc*(y[a]-y[b]))/divisor
    let cy=(aa*(x[c]-x[b])+bb*(x[a]-x[c])+cc*(x[b]-x[a]))/divisor
    let dx=cx-x[a]; let dy=cy-y[a]
    let bottom=cy-sqrt(dx*dx+dy*dy)
    return (bottom<line-1.0e-10,bottom)

fn fortune_neighbors(n: Int, x: InlineArray[Float64, 8], y: InlineArray[Float64, 8],
                     mut neighbors: InlineArray[Bool, 64]) -> Bool:
    var order=InlineArray[Int, 8](fill=0)
    for i in range(n): order[i]=i
    for i in range(1,n):
        let site=order[i]; var j=i
        while j>0 and y[order[j-1]]<y[site]:
            order[j]=order[j-1]; j-=1
        order[j]=site
    var sites=InlineArray[Int, 15](fill=0)
    var previous=InlineArray[Int, 15](fill=-1)
    var next=InlineArray[Int, 15](fill=-1)
    sites[0]=order[0]
    var total=1; var site_index=1; var line=y[order[0]]
    while True:
        var best_arc = -1; var best_left = -1; var best_right = -1
        var best_y=Float64(0); var arc=0
        while arc>=0:
            let left=previous[arc]; let right=next[arc]
            if left>=0 and right>=0:
                let a=sites[left]; let b=sites[arc]; let c=sites[right]
                if a!=b and b!=c and a!=c:
                    let event=fortune_circle(x,y,a,b,c,line)
                    if event[0] and (best_arc<0 or event[1]>best_y+1.0e-10 or
                            (abs(event[1]-best_y)<=1.0e-10 and arc<best_arc)):
                        best_arc=arc; best_left=left; best_right=right; best_y=event[1]
            arc=next[arc]
        let insert = site_index<n and (best_arc<0 or y[order[site_index]]>best_y+1.0e-10)
        if not insert and best_arc<0: break
        if insert:
            let site=order[site_index]; site_index+=1; line=y[site]
            var current=0
            while next[current]>=0:
                let r=next[current]
                if x[site]<fortune_breakpoint(x[sites[current]],y[sites[current]],x[sites[r]],y[sites[r]],line): break
                current=r
            if total+2>15: return False
            let old_next=next[current]; let old_site=sites[current]
            let middle=total; let right=total+1; total+=2
            sites[middle]=site; sites[right]=old_site
            previous[middle]=current; next[middle]=right
            previous[right]=middle; next[right]=old_next
            next[current]=middle
            if old_next>=0: previous[old_next]=right
            neighbors[8*old_site+site]=True; neighbors[8*site+old_site]=True
        else:
            line=best_y
            let a=sites[best_left]; let b=sites[best_right]
            neighbors[8*a+b]=True; neighbors[8*b+a]=True
            next[best_left]=best_right; previous[best_right]=best_left
    return True

@export("fortune_voronoi")
fn fortune_voronoi(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64, ImmutAnyOrigin]() or length<3: return -1
    if input[0]<1 or input[0]>8: return -1
    let n=Int(input[0])
    if length!=c_size_t(1+2*n): return -1
    var ix=InlineArray[Int64,8](fill=0); var iy=InlineArray[Int64,8](fill=0)
    var x=InlineArray[Float64,8](fill=0); var y=InlineArray[Float64,8](fill=0)
    for i in range(n):
        ix[i]=input[1+2*i]; iy[i]=input[2+2*i]
        if ix[i]< -8 or ix[i]>8 or iy[i]< -8 or iy[i]>8: return -1
        for j in range(i):
            if iy[i]==iy[j]: return -1
        x[i]=Float64(ix[i]); y[i]=Float64(iy[i])
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                if (ix[b]-ix[a])*(iy[c]-iy[a])==(iy[b]-iy[a])*(ix[c]-ix[a]): return -1
                for d in range(c+1,n):
                    let ax=ix[a]-ix[d]; let ay=iy[a]-iy[d]
                    let bx=ix[b]-ix[d]; let by=iy[b]-iy[d]
                    let cx=ix[c]-ix[d]; let cy=iy[c]-iy[d]
                    let aa=ax*ax+ay*ay; let bb=bx*bx+by*by; let cc=cx*cx+cy*cy
                    if ax*(by*cc-bb*cy)-ay*(bx*cc-bb*cx)+aa*(bx*cy-by*cx)==0: return -1
    var neighbors=InlineArray[Bool,64](fill=False)
    if not fortune_neighbors(n,x,y,neighbors): return -1
    var words=InlineArray[Int64,369](fill=0)
    words[0]=Int64(n); var used=1
    let neg=FortuneRat(-16,1); let pos=FortuneRat(16,1); let zero=FortuneRat(0,1)
    for i in range(n):
        var polygon=InlineArray[FortunePoint,32](fill=FortunePoint(zero,zero))
        polygon[0]=FortunePoint(neg,neg); polygon[1]=FortunePoint(pos,neg)
        polygon[2]=FortunePoint(pos,pos); polygon[3]=FortunePoint(neg,pos)
        var count=4
        for j in range(n):
            if neighbors[8*i+j]:
                let a=2*(ix[j]-ix[i]); let b=2*(iy[j]-iy[i])
                let c=ix[j]*ix[j]+iy[j]*iy[j]-ix[i]*ix[i]-iy[i]*iy[i]
                count=fortune_clip(polygon,count,a,b,c)
                if count<0: return -1
        if count<3 or used+2+4*count>369: return -1
        var start=0
        for j in range(1,count):
            let cmp=fortune_cmp(polygon[j].x,polygon[start].x)
            if cmp<0 or (cmp==0 and fortune_cmp(polygon[j].y,polygon[start].y)<0): start=j
        words[used]=Int64(i); words[used+1]=Int64(count); used+=2
        for j in range(count):
            let point=polygon[(start+j)%count]
            words[used]=point.x.numerator; words[used+1]=point.x.denominator
            words[used+2]=point.y.numerator; words[used+3]=point.y.denominator
            used+=4
    let bytes=8*used
    if output==UnsafePointer[UInt8, MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    for i in range(used):
        let bits=bitcast[UInt64](words[i])
        for b in range(8): output[8*i+b]=UInt8((bits>>UInt(8*b)) & UInt64(255))
    return Int64(bytes)
