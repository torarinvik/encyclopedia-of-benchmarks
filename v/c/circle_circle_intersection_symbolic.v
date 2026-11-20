// Independently authored draft; not compiled or run.
module circle_circle_intersection_symbolic

@[export: 'circle_circle_intersection_symbolic']
pub fn circle_circle_intersection_symbolic(v &i64, n usize, mut out &u8, cap usize) i64 {
    unsafe {
        if v == nil || n != 6 { return -1 }
        for i in 0 .. 6 { if v[i] < -1000 || v[i] > 1000 { return -1 } }
        if v[2] < 1 || v[5] < 1 { return -1 }
        dx,dy := v[3]-v[0],v[4]-v[1]
        d := dx*dx+dy*dy
        mut words := [7]i64{}
        mut count := 1
        if d == 0 {
            if v[2] == v[5] { words[0]=3 }
        } else {
            t := d+v[2]*v[2]-v[5]*v[5]
            h := 4*v[2]*v[2]*d-t*t
            if h >= 0 {
                den := 2*d
                count=7
                words[0]=if h == 0 { 1 } else { 2 }
                words[1]=den*v[0]+dx*t; words[2]=den*v[1]+dy*t
                words[3]=den; words[4]=-dy; words[5]=dx; words[6]=h
            }
        }
        needed := 8*count
        if out == nil || cap < usize(needed) { return -2 }
        for i in 0 .. count {
            bits := u64(words[i])
            for j in 0 .. 8 { out[8*i+j]=u8((bits >> (8*j)) & 255) }
        }
        return i64(needed)
    }
}
