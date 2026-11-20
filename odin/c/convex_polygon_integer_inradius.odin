// Independently authored draft; not compiled or run.
package convex_polygon_integer_inradius
import "core:c"

Line :: struct { a,b,c,norm: i64 }
Point :: struct { x,y,den: i64 }
abs64 :: proc(x:i64) -> i64 {
    if x < 0 do return -x
    return x
}
gcd64 :: proc(x,y:i64) -> i64 {
    a,b := abs64(x),abs64(y)
    for b!=0 { r:=a%b; a=b; b=r }
    return a
}
half :: proc(l:Line) -> int {
    if l.b>0 || (l.b==0 && l.a>=0) do return 0
    return 1
}
before :: proc(a,b:Line) -> bool {
    ha,hb := half(a),half(b)
    if ha!=hb do return ha<hb
    cross := a.a*b.b-a.b*b.a
    if cross!=0 do return cross>0
    return a.c<b.c
}
intersect :: proc(a,b:Line,p:^Point) -> bool {
    den:=a.a*b.b-b.a*a.b
    if den==0 do return false
    x,y:=a.c*b.b-a.b*b.c,a.a*b.c-a.c*b.a
    if den<0 { den=-den; x=-x; y=-y }
    p^=Point{x,y,den}
    return true
}
outside :: proc(l:Line,p:Point) -> bool { return l.a*p.x+l.b*p.y>l.c*p.den }
feasible :: proc(lines:[]Line,radius:i64) -> bool {
    queue:[16]Line; head,tail:=0,0
    for line in lines {
        h:=line; h.c=h.c*32768-(radius*32768-1)*h.norm
        if tail>head && queue[tail-1].a==h.a && queue[tail-1].b==h.b {
            if h.c>=queue[tail-1].c do continue
            tail-=1
        }
        p:Point
        for tail-head>1 && intersect(queue[tail-2],queue[tail-1],&p) && outside(h,p) { tail-=1 }
        for tail-head>1 && intersect(queue[head],queue[head+1],&p) && outside(h,p) { head+=1 }
        if tail>head && queue[tail-1].a*h.b-queue[tail-1].b*h.a==0 do return false
        queue[tail]=h; tail+=1
    }
    p:Point
    for tail-head>2 && intersect(queue[tail-2],queue[tail-1],&p) && outside(queue[head],p) { tail-=1 }
    for tail-head>2 && intersect(queue[head],queue[head+1],&p) && outside(queue[tail-1],p) { head+=1 }
    if tail-head<3 do return false
    for i:=head;i<tail;i+=1 {
        j:=i+1
        if j==tail { j=head }
        if !intersect(queue[i],queue[j],&p) do return false
    }
    return true
}

@(export)
convex_polygon_integer_inradius :: proc "c" (input:[^]i64,length:c.size_t) -> i64 {
    if input==nil || length<1 || length>38 do return -1
    if input[0]<0 || input[0]>12 do return -1
    n:=int(input[0])
    if length!=c.size_t(1+3*n) do return -1
    lines:[16]Line
    for i:=0;i<n;i+=1 {
        a,b,c0:=input[1+3*i],input[2+3*i],input[3+3*i]
        if a < -15 || a>15 || b < -15 || b>15 || c0 < -128 || c0>128 do return -1
        squared:=a*a+b*b; norm:=i64(0)
        for norm*norm<squared { norm+=1 }
        if norm==0 || norm*norm!=squared || gcd64(a,b)!=1 do return -1
        lines[i]=Line{a,b,c0,norm}
    }
    lines[n]=Line{1,0,256,1}; lines[n+1]=Line{0,1,256,1}
    lines[n+2]=Line{-1,0,256,1}; lines[n+3]=Line{0,-1,256,1}
    count:=n+4; scratch:[16]Line; width:=1
    for width<count {
        for start:=0;start<count;start+=2*width {
            middle:=min(start+width,count); end:=min(start+2*width,count)
            i,j,k:=start,middle,start
            for i<middle && j<end {
                if before(lines[j],lines[i]) { scratch[k]=lines[j]; j+=1 }
                else { scratch[k]=lines[i]; i+=1 }
                k+=1
            }
            for i<middle { scratch[k]=lines[i]; i+=1; k+=1 }
            for j<end { scratch[k]=lines[j]; j+=1; k+=1 }
        }
        for i:=0;i<count;i+=1 { lines[i]=scratch[i] }
        width*=2
    }
    if !feasible(lines[:count],0) do return -2
    low,high:=i64(0),i64(257)
    for high-low>1 {
        middle:=(low+high)/2
        if feasible(lines[:count],middle) { low=middle } else { high=middle }
    }
    return low
}
