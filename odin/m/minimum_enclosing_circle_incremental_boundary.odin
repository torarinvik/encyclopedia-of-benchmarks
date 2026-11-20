// Independently authored draft; not compiled or run.
package minimum_enclosing_circle_incremental_boundary
import "core:c"
Point :: struct { x,y: i64 }
Circle :: struct { x,y,den,radius2: i64 }
distance :: proc(c: Circle, p: Point) -> i64 {
    dx := p.x*c.den-c.x; dy := p.y*c.den-c.y
    return dx*dx+dy*dy
}
point_circle :: proc(p: Point) -> Circle { return Circle{p.x,p.y,1,0} }
pair_circle :: proc(a,b: Point) -> Circle {
    result := Circle{a.x+b.x,a.y+b.y,2,0}
    result.radius2 = distance(result,a)
    return result
}
triple_circle :: proc(a,b,c: Point) -> Circle {
    den := 2*(a.x*(b.y-c.y)+b.x*(c.y-a.y)+c.x*(a.y-b.y))
    if den == 0 {
        ab,ac,bc := pair_circle(a,b),pair_circle(a,c),pair_circle(b,c)
        if ab.radius2 >= ac.radius2 && ab.radius2 >= bc.radius2 do return ab
        if ac.radius2 >= bc.radius2 do return ac
        return bc
    }
    aa,bb,cc := a.x*a.x+a.y*a.y,b.x*b.x+b.y*b.y,c.x*c.x+c.y*c.y
    x := aa*(b.y-c.y)+bb*(c.y-a.y)+cc*(a.y-b.y)
    y := aa*(c.x-b.x)+bb*(a.x-c.x)+cc*(b.x-a.x)
    if den < 0 { den = -den; x = -x; y = -y }
    result := Circle{x,y,den,0}
    result.radius2 = distance(result,a)
    return result
}
@(export)
minimum_enclosing_circle_incremental_boundary :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > 194 || input[0] < 1 || input[0] > 64 do return -1
    n := int(input[0])
    if length != c.size_t(1+3*n) do return -1
    points: [64]Point; order: [64]int; seen: [64]bool
    for i := 0; i < n; i += 1 {
        x,y := input[1+2*i],input[2+2*i]
        if x < -100 || x > 100 || y < -100 || y > 100 do return -1
        points[i] = Point{x,y}
    }
    for i := 0; i < n; i += 1 {
        v := input[1+2*n+i]
        if v < 0 || v >= i64(n) do return -1
        if seen[int(v)] do return -1
        order[i] = int(v); seen[int(v)] = true
    }
    if output == nil || capacity < c.size_t(n) do return -2
    circle := point_circle(points[order[0]])
    for i := 1; i < n; i += 1 {
        a := points[order[i]]
        if distance(circle,a) <= circle.radius2 do continue
        circle = point_circle(a)
        for j := 0; j < i; j += 1 {
            b := points[order[j]]
            if distance(circle,b) <= circle.radius2 do continue
            circle = pair_circle(a,b)
            for k := 0; k < j; k += 1 {
                p := points[order[k]]
                if distance(circle,p) > circle.radius2 { circle = triple_circle(a,b,p) }
            }
        }
    }
    for i := 0; i < n; i += 1 {
        if distance(circle,points[i]) == circle.radius2 { output[i] = 1 } else { output[i] = 0 }
    }
    return i64(n)
}
