# Independent bounded Bowyer-Watson triangulation; see package LICENSE.md.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dt_orient(x: InlineArray[Int64,11], y: InlineArray[Int64,11], a: Int, b: Int, c: Int) -> Int64:
    return (x[b]-x[a])*(y[c]-y[a])-(y[b]-y[a])*(x[c]-x[a])

fn dt_incircle(x: InlineArray[Int64,11], y: InlineArray[Int64,11], a: Int, b: Int, c: Int, d: Int) -> Int64:
    let ax=x[a]-x[d]; let ay=y[a]-y[d]
    let bx=x[b]-x[d]; let by=y[b]-y[d]
    let cx=x[c]-x[d]; let cy=y[c]-y[d]
    return (ax*ax+ay*ay)*(bx*cy-by*cx)-(bx*bx+by*by)*(ax*cy-ay*cx)+(cx*cx+cy*cy)*(ax*by-ay*bx)

fn dt_circle(px: InlineArray[Float64,11], py: InlineArray[Float64,11], a: Int, b: Int, c: Int) -> (Float64,Float64,Float64):
    let ax=px[b]-px[a]; let ay=py[b]-py[a]
    let bx=px[c]-px[a]; let by=py[c]-py[a]
    let m=px[b]*px[b]-px[a]*px[a]+py[b]*py[b]-py[a]*py[a]
    let u=px[c]*px[c]-px[a]*px[a]+py[c]*py[c]-py[a]*py[a]
    let scale=1.0/(2.0*(ax*by-ay*bx))
    let x=(by*m-ay*u)*scale
    let y=(-bx*m+ax*u)*scale
    let dx=px[a]-x; let dy=py[a]-y
    return (x,y,dx*dx+dy*dy)

@export("delaunay_triangulation")
fn delaunay_triangulation(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<7 or length>17: return -1
    if input[0]<3 or input[0]>8: return -1
    let n=Int(input[0])
    if length!=c_size_t(1+2*n): return -1
    var x=InlineArray[Int64,11](fill=0); var y=InlineArray[Int64,11](fill=0)
    var px=InlineArray[Float64,11](fill=0); var py=InlineArray[Float64,11](fill=0)
    var min_x=Int64(0); var max_x=Int64(0); var min_y=Int64(0); var max_y=Int64(0)
    for i in range(n):
        x[i]=input[1+2*i]; y[i]=input[2+2*i]
        if x[i] < -10 or x[i]>10 or y[i] < -10 or y[i]>10: return -1
        for j in range(i):
            if x[i]==x[j] and y[i]==y[j]: return -1
        px[i]=Float64(x[i]); py[i]=Float64(y[i])
        if i==0:
            min_x=x[i]; max_x=x[i]; min_y=y[i]; max_y=y[i]
        else:
            min_x=min(min_x,x[i]); max_x=max(max_x,x[i])
            min_y=min(min_y,y[i]); max_y=max(max_y,y[i])
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                if dt_orient(x,y,a,b,c)==0: return -1
                for d in range(c+1,n):
                    if dt_incircle(x,y,a,b,c,d)==0: return -1
    let extent=Float64(max(max_x-min_x,max_y-min_y))
    let mx=Float64(min_x+max_x)/2.0; let my=Float64(min_y+max_y)/2.0
    px[n]=mx-20.0*extent; py[n]=my-extent
    px[n+1]=mx; py[n+1]=my+20.0*extent
    px[n+2]=mx+20.0*extent; py[n+2]=my-extent
    for a in range(n+3):
        for b in range(a+1,n+3):
            for c in range(b+1,n+3):
                if (px[b]-px[a])*(py[c]-py[a])-(py[b]-py[a])*(px[c]-px[a])==0.0: return -1
    var triangles=InlineArray[Int,51](fill=0)
    var next=InlineArray[Int,51](fill=0)
    triangles[0]=n; triangles[1]=n+1; triangles[2]=n+2
    var count=1
    for point in range(n):
        var ea=InlineArray[Int,51](fill=0); var eb=InlineArray[Int,51](fill=0)
        var edge_count=0; var next_count=0
        for i in range(count):
            let a=triangles[3*i]; let b=triangles[3*i+1]; let c=triangles[3*i+2]
            let circle=dt_circle(px,py,a,b,c)
            let dx=circle[0]-px[point]; let dy=circle[1]-py[point]
            if dx*dx+dy*dy-circle[2]<=0.0001:
                ea[edge_count]=a; eb[edge_count]=b; edge_count+=1
                ea[edge_count]=b; eb[edge_count]=c; edge_count+=1
                ea[edge_count]=a; eb[edge_count]=c; edge_count+=1
            else:
                if next_count>=17: return -1
                next[3*next_count]=a; next[3*next_count+1]=b; next[3*next_count+2]=c
                next_count+=1
        for i in range(edge_count):
            var duplicate=False
            for j in range(edge_count):
                if i!=j and ((ea[i]==ea[j] and eb[i]==eb[j]) or (ea[i]==eb[j] and eb[i]==ea[j])): duplicate=True
            if not duplicate:
                if next_count>=17: return -1
                next[3*next_count]=ea[i]; next[3*next_count+1]=eb[i]; next[3*next_count+2]=point
                next_count+=1
        for i in range(3*next_count): triangles[i]=next[i]
        count=next_count
    var result=InlineArray[Int,33](fill=0)
    var result_count=0
    for i in range(count):
        var a=triangles[3*i]; var b=triangles[3*i+1]; var c=triangles[3*i+2]
        if a>=n or b>=n or c>=n: continue
        if result_count>=11: return -1
        if a>b:
            let t=a
            a=b; b=t
        if b>c:
            let t=b
            b=c; c=t
        if a>b:
            let t=a
            a=b; b=t
        var j=result_count
        while j>0 and (a<result[3*(j-1)] or (a==result[3*(j-1)] and (b<result[3*(j-1)+1] or (b==result[3*(j-1)+1] and c<result[3*(j-1)+2])))):
            for k in range(3): result[3*j+k]=result[3*(j-1)+k]
            j-=1
        result[3*j]=a; result[3*j+1]=b; result[3*j+2]=c
        result_count+=1
    if result_count==0: return -1
    let needed=8+24*result_count
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed): return -2
    for i in range(1+3*result_count):
        let value=result_count if i==0 else result[i-1]
        let bits=UInt64(value)
        for byte in range(8): output[8*i+byte]=UInt8((bits >> UInt(8*byte)) & 255)
    return Int64(needed)
