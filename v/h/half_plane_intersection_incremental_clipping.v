// Independently authored draft; not compiled or run.
module half_plane_intersection_incremental_clipping

struct ClipLine { a i64; b i64; c i64 }
struct ClipVertex { x i64; y i64; den i64; incoming int }
fn clip_gcd(a0 i64, b0 i64) i64 {
    mut a := if a0 < 0 { -a0 } else { a0 }
    mut b := if b0 < 0 { -b0 } else { b0 }
    for b != 0 { r := a%b; a = b; b = r }
    return a
}
fn clip_intersect(a ClipLine, b ClipLine) ?ClipVertex {
    mut den := a.a*b.b-b.a*a.b
    if den == 0 { return none }
    mut x := a.c*b.b-a.b*b.c
    mut y := a.a*b.c-a.c*b.a
    if den < 0 { den = -den; x = -x; y = -y }
    g := clip_gcd(clip_gcd(x,y),den)
    return ClipVertex{x/g,y/g,den/g,0}
}
fn clip_side(l ClipLine, p ClipVertex) i64 { return l.a*p.x+l.b*p.y-l.c*p.den }
fn clip_same(a ClipVertex, b ClipVertex) bool { return a.x*b.den==b.x*a.den && a.y*b.den==b.y*a.den }
fn clip_turn(a ClipVertex, b ClipVertex, c ClipVertex) i64 {
    dx1 := b.x*a.den-a.x*b.den; dy1 := b.y*a.den-a.y*b.den
    dx2 := c.x*b.den-b.x*c.den; dy2 := c.y*b.den-b.y*c.den
    return dx1*dy2-dy1*dx2
}
fn clip_put(mut output &u8, offset int, value i64) {
    bits := u64(value)
    for i in 0 .. 8 {
        unsafe { output[offset+i] = u8((bits >> (8*i)) & 255) }
    }
}
@[export: 'half_plane_intersection_incremental_clipping']
pub fn half_plane_intersection_incremental_clipping(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input==nil || length<1 || length>38 || input[0]<0 || input[0]>12 { return -1 }
        n:=int(input[0])
        if length!=usize(1+3*n) { return -1 }
        mut lines := [16]ClipLine{}
        lines[0]=ClipLine{-1,0,256}; lines[1]=ClipLine{0,-1,256}
        lines[2]=ClipLine{1,0,256}; lines[3]=ClipLine{0,1,256}
        for i in 0 .. n {
            a:=input[1+3*i]; b:=input[2+3*i]; c:=input[3+3*i]
            if a < -16 || a > 16 || b < -16 || b > 16 || c < -128 || c > 128 || (a==0 && b==0) || clip_gcd(a,b)!=1 { return -1 }
            lines[4+i]=ClipLine{a,b,c}
        }
        mut polygon := [32]ClipVertex{}
        polygon[0]=ClipVertex{-256,-256,1,0}; polygon[1]=ClipVertex{256,-256,1,1}
        polygon[2]=ClipVertex{256,256,1,2}; polygon[3]=ClipVertex{-256,256,1,3}
        mut count:=4
        for line in 4 .. 4+n {
            if count<3 { break }
            mut next:=[32]ClipVertex{}
            mut used:=0
            for i in 0 .. count {
                s:=polygon[(i+count-1)%count]; e:=polygon[i]
                s_in:=clip_side(lines[line],s)<=0; e_in:=clip_side(lines[line],e)<=0
                if s_in!=e_in {
                    crossing:=clip_intersect(lines[e.incoming],lines[line]) or { return -1 }
                    p:=ClipVertex{crossing.x,crossing.y,crossing.den,if s_in { e.incoming } else { line }}
                    if used==0 || !clip_same(next[used-1],p) { next[used]=p; used++ }
                }
                if e_in && (used==0 || !clip_same(next[used-1],e)) { next[used]=e; used++ }
            }
            if used>1 && clip_same(next[0],next[used-1]) {
                first:=next[0]; next[0]=ClipVertex{first.x,first.y,first.den,next[used-1].incoming}
                used--
            }
            count=used; polygon=next
            mut noncollinear:=false
            if count>=3 {
                for i in 0 .. count {
                    if clip_turn(polygon[i],polygon[(i+1)%count],polygon[(i+2)%count])!=0 { noncollinear=true }
                }
            }
            if !noncollinear { count=0 }
        }
        mut changed:=true
        for changed && count>=3 {
            changed=false
            for i in 0 .. count {
                if clip_turn(polygon[(i+count-1)%count],polygon[i],polygon[(i+1)%count])==0 {
                    for j:=i; j+1<count; j++ { polygon[j]=polygon[j+1] }
                    count--; changed=true; break
                }
            }
        }
        if count<3 { count=0 }
        mut first:=0
        for i in 1 .. count {
            yi:=polygon[i].y*polygon[first].den; yf:=polygon[first].y*polygon[i].den
            if yi<yf || (yi==yf && polygon[i].x*polygon[first].den<polygon[first].x*polygon[i].den) { first=i }
        }
        needed:=(1+4*count)*8
        if output==nil || capacity<usize(needed) { return -2 }
        clip_put(mut output,0,i64(count))
        for i in 0 .. count {
            p:=polygon[(first+i)%count]
            gx:=clip_gcd(p.x,p.den); gy:=clip_gcd(p.y,p.den)
            base:=8+32*i
            clip_put(mut output,base,p.x/gx); clip_put(mut output,base+8,p.den/gx)
            clip_put(mut output,base+16,p.y/gy); clip_put(mut output,base+24,p.den/gy)
        }
        return i64(needed)
    }
}
