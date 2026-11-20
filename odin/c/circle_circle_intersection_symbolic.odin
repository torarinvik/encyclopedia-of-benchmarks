// Independently authored draft; not compiled or run.
package circle_circle_intersection_symbolic
import "core:c"

@(export)
circle_circle_intersection_symbolic :: proc "c" (v: [^]i64, n: c.size_t,
        out: [^]u8, cap: c.size_t) -> i64 {
    if v == nil || n != 6 do return -1
    for i := 0; i < 6; i += 1 {
        if v[i] < -1000 || v[i] > 1000 do return -1
    }
    if v[2] < 1 || v[5] < 1 do return -1
    dx,dy := v[3]-v[0],v[4]-v[1]
    d := dx*dx+dy*dy
    words: [7]i64 = {}
    count := 1
    if d == 0 {
        if v[2] == v[5] { words[0]=3 }
    } else {
        t := d+v[2]*v[2]-v[5]*v[5]
        h := 4*v[2]*v[2]*d-t*t
        if h >= 0 {
            den := 2*d
            count=7
            if h == 0 { words[0]=1 } else { words[0]=2 }
            words[1]=den*v[0]+dx*t; words[2]=den*v[1]+dy*t
            words[3]=den; words[4]=-dy; words[5]=dx; words[6]=h
        }
    }
    needed := 8*count
    if out == nil || cap < c.size_t(needed) do return -2
    for i := 0; i < count; i += 1 {
        bits := transmute(u64)words[i]
        for j := 0; j < 8; j += 1 do out[8*i+j]=u8((bits >> uint(8*j)) & 255)
    }
    return i64(needed)
}
