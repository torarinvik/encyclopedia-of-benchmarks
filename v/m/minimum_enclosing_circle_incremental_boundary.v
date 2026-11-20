// Independently authored draft; not compiled or run.
struct MecPoint { x i64; y i64 }
struct MecCircle { x i64; y i64; den i64; radius2 i64 }
fn mec_distance(c MecCircle, p MecPoint) i64 {
    dx := p.x*c.den-c.x
    dy := p.y*c.den-c.y
    return dx*dx+dy*dy
}
fn mec_point(p MecPoint) MecCircle { return MecCircle{p.x,p.y,1,0} }
fn mec_pair(a MecPoint, b MecPoint) MecCircle {
    mut c := MecCircle{a.x+b.x,a.y+b.y,2,0}
    c = MecCircle{c.x,c.y,c.den,mec_distance(c,a)}
    return c
}
fn mec_triple(a MecPoint, b MecPoint, c MecPoint) MecCircle {
    mut den := 2*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y))
    if den == 0 {
        ab := mec_pair(a,b); ac := mec_pair(a,c); bc := mec_pair(b,c)
        if ab.radius2 >= ac.radius2 && ab.radius2 >= bc.radius2 { return ab }
        if ac.radius2 >= bc.radius2 { return ac }
        return bc
    }
    aa := a.x*a.x+a.y*a.y; bb := b.x*b.x+b.y*b.y; cc := c.x*c.x+c.y*c.y
    mut x := aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y)
    mut y := aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x)
    if den < 0 { den = -den; x = -x; y = -y }
    result := MecCircle{x,y,den,0}
    return MecCircle{x,y,den,mec_distance(result,a)}
}
@[export: 'minimum_enclosing_circle_incremental_boundary']
pub fn minimum_enclosing_circle_incremental_boundary(input &i64, length usize, mut output &u8, capacity usize) i64 {
    unsafe {
        if input == nil || length < 4 || length > 194 || input[0] < 1 || input[0] > 64 { return -1 }
        n := int(input[0])
        if length != usize(1+3*n) { return -1 }
        mut points := [64]MecPoint{}
        mut order := [64]int{}
        mut seen := [64]bool{}
        for i in 0 .. n {
            x := input[1+2*i]; y := input[2+2*i]
            if x < -100 || x > 100 || y < -100 || y > 100 { return -1 }
            points[i] = MecPoint{x,y}
        }
        for i in 0 .. n {
            v := input[1+2*n+i]
            if v < 0 || v >= i64(n) { return -1 }
            if seen[int(v)] { return -1 }
            order[i] = int(v); seen[int(v)] = true
        }
        if output == nil || capacity < usize(n) { return -2 }
        mut circle := mec_point(points[order[0]])
        for i in 1 .. n {
            a := points[order[i]]
            if mec_distance(circle,a) <= circle.radius2 { continue }
            circle = mec_point(a)
            for j in 0 .. i {
                b := points[order[j]]
                if mec_distance(circle,b) <= circle.radius2 { continue }
                circle = mec_pair(a,b)
                for k in 0 .. j {
                    c := points[order[k]]
                    if mec_distance(circle,c) > circle.radius2 { circle = mec_triple(a,b,c) }
                }
            }
        }
        for i in 0 .. n {
            output[i] = if mec_distance(circle,points[i]) == circle.radius2 { u8(1) } else { u8(0) }
        }
        return i64(n)
    }
}
