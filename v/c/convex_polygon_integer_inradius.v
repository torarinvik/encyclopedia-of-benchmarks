// Independently authored draft; not compiled or run.
module convex_polygon_integer_inradius

struct Line { a i64; b i64; c i64; norm i64 }
struct Point { x i64; y i64; den i64 }
fn gcd64(x i64,y i64) i64 {
    mut a:=if x<0 { -x } else { x }; mut b:=if y<0 { -y } else { y }
    for b!=0 { r:=a%b; a=b; b=r }
    return a
}
fn half(l Line) int { return if l.b>0 || (l.b==0 && l.a>=0) { 0 } else { 1 } }
fn before(a Line,b Line) bool {
    ha:=half(a); hb:=half(b)
    if ha!=hb { return ha<hb }
    cross:=a.a*b.b-a.b*b.a
    return if cross!=0 { cross>0 } else { a.c<b.c }
}
fn intersect(a Line,b Line) ?Point {
    mut den:=a.a*b.b-b.a*a.b
    if den==0 { return none }
    mut x:=a.c*b.b-a.b*b.c; mut y:=a.a*b.c-a.c*b.a
    if den<0 { den=-den; x=-x; y=-y }
    return Point{x,y,den}
}
fn outside(l Line,p Point) bool { return l.a*p.x+l.b*p.y>l.c*p.den }
fn feasible(lines [16]Line,count int,radius i64) bool {
    mut queue:=[16]Line{}; mut head:=0; mut tail:=0
    for i in 0 .. count {
        l:=lines[i]
        h:=Line{l.a,l.b,l.c*32768-(radius*32768-1)*l.norm,l.norm}
        if tail>head && queue[tail-1].a==h.a && queue[tail-1].b==h.b {
            if h.c>=queue[tail-1].c { continue }
            tail--
        }
        for tail-head>1 {
            p:=intersect(queue[tail-2],queue[tail-1]) or { break }
            if !outside(h,p) { break }
            tail--
        }
        for tail-head>1 {
            p:=intersect(queue[head],queue[head+1]) or { break }
            if !outside(h,p) { break }
            head++
        }
        if tail>head && queue[tail-1].a*h.b-queue[tail-1].b*h.a==0 { return false }
        queue[tail]=h; tail++
    }
    for tail-head>2 {
        p:=intersect(queue[tail-2],queue[tail-1]) or { break }
        if !outside(queue[head],p) { break }
        tail--
    }
    for tail-head>2 {
        p:=intersect(queue[head],queue[head+1]) or { break }
        if !outside(queue[tail-1],p) { break }
        head++
    }
    if tail-head<3 { return false }
    for i in head .. tail {
        j:=if i+1==tail { head } else { i+1 }
        _ := intersect(queue[i],queue[j]) or { return false }
    }
    return true
}
@[export: 'convex_polygon_integer_inradius']
pub fn convex_polygon_integer_inradius(input &i64,length usize) i64 {
    unsafe {
        if input==nil || length<1 || length>38 { return -1 }
        if input[0]<0 || input[0]>12 { return -1 }
        n:=int(input[0])
        if length!=usize(1+3*n) { return -1 }
        mut lines:=[16]Line{}
        for i in 0 .. n {
            a:=input[1+3*i]; b:=input[2+3*i]; c:=input[3+3*i]
            if a < -15 || a>15 || b < -15 || b>15 || c < -128 || c>128 { return -1 }
            squared:=a*a+b*b; mut norm:=i64(0)
            for norm*norm<squared { norm++ }
            if norm==0 || norm*norm!=squared || gcd64(a,b)!=1 { return -1 }
            lines[i]=Line{a,b,c,norm}
        }
        lines[n]=Line{1,0,256,1}; lines[n+1]=Line{0,1,256,1}
        lines[n+2]=Line{-1,0,256,1}; lines[n+3]=Line{0,-1,256,1}
        count:=n+4; mut scratch:=[16]Line{}; mut width:=1
        for width<count {
            mut start:=0
            for start<count {
                middle:=if start+width<count { start+width } else { count }
                end:=if start+2*width<count { start+2*width } else { count }
                mut i:=start; mut j:=middle; mut k:=start
                for i<middle && j<end {
                    if before(lines[j],lines[i]) { scratch[k]=lines[j]; j++ }
                    else { scratch[k]=lines[i]; i++ }
                    k++
                }
                for i<middle { scratch[k]=lines[i]; i++; k++ }
                for j<end { scratch[k]=lines[j]; j++; k++ }
                start+=2*width
            }
            for i in 0 .. count { lines[i]=scratch[i] }
            width*=2
        }
        if !feasible(lines,count,0) { return -2 }
        mut low:=i64(0); mut high:=i64(257)
        for high-low>1 {
            mid:=(low+high)/2
            if feasible(lines,count,mid) { low=mid } else { high=mid }
        }
        return low
    }
}
