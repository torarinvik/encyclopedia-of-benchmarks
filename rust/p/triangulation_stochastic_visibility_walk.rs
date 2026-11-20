use std::slice;

const MAX_V: usize = 6;
const MAX_B: usize = 6;
const MAX_T: usize = 7;
const MAX_CAP: i64 = 12;
const MAX_K: i64 = 12;

fn orient(points: &[(i64, i64); MAX_V], a: usize, b: usize, c: (i64, i64)) -> i64 {
    (points[b].0 - points[a].0) * (c.1 - points[a].1)
        - (points[b].1 - points[a].1) * (c.0 - points[a].0)
}

fn same_edge(a: usize, b: usize, c: usize, d: usize) -> bool {
    (a == c && b == d) || (a == d && b == c)
}

fn on_segment(points: &[(i64, i64); MAX_V], a: usize, b: usize, p: usize) -> bool {
    orient(points, a, b, points[p]) == 0
        && points[p].0 >= points[a].0.min(points[b].0)
        && points[p].0 <= points[a].0.max(points[b].0)
        && points[p].1 >= points[a].1.min(points[b].1)
        && points[p].1 <= points[a].1.max(points[b].1)
}

fn segments_intersect(points: &[(i64, i64); MAX_V], a: usize, b: usize, c: usize, d: usize) -> bool {
    let o1 = orient(points, a, b, points[c]);
    let o2 = orient(points, a, b, points[d]);
    let o3 = orient(points, c, d, points[a]);
    let o4 = orient(points, c, d, points[b]);
    if (o1 == 0 && on_segment(points, a, b, c))
        || (o2 == 0 && on_segment(points, a, b, d))
        || (o3 == 0 && on_segment(points, c, d, a))
        || (o4 == 0 && on_segment(points, c, d, b))
    {
        return true;
    }
    ((o1 < 0 && o2 > 0) || (o1 > 0 && o2 < 0))
        && ((o3 < 0 && o4 > 0) || (o3 > 0 && o4 < 0))
}

#[no_mangle]
pub unsafe extern "C" fn triangulation_stochastic_visibility_walk(
    input_ptr: *const i64,
    length: usize,
) -> i64 {
    if input_ptr.is_null() || !(8..=57).contains(&length) {
        return -1;
    }
    let input = slice::from_raw_parts(input_ptr, length);
    let (vr, br, tr, sr) = (input[0], input[1], input[2], input[3]);
    let (px, py, cap, kr) = (input[4], input[5], input[6], input[7]);
    if !(3..=MAX_V as i64).contains(&vr)
        || br < 3 || br > vr
        || tr != 2 * vr - br - 2 || !(1..=MAX_T as i64).contains(&tr)
        || sr < 0 || sr >= tr || !(0..=MAX_CAP).contains(&cap)
        || !(0..=MAX_K).contains(&kr)
        || !(-200..=200).contains(&px) || !(-200..=200).contains(&py)
    {
        return -1;
    }
    let (v, bcount, tcount, start, k) = (vr as usize, br as usize, tr as usize, sr as usize, kr as usize);
    if length != 8 + 2 * v + bcount + 3 * tcount + k {
        return -1;
    }

    let mut points = [(0_i64, 0_i64); MAX_V];
    let mut boundary = [0_usize; MAX_B];
    let mut faces = [[0_usize; 3]; MAX_T];
    let mut neighbors = [[-1_i64; 3]; MAX_T];
    let mut used = [false; MAX_V];
    let mut cursor = 8;
    for point in points.iter_mut().take(v) {
        let (x, y) = (input[cursor], input[cursor + 1]);
        cursor += 2;
        if !(-200..=200).contains(&x) || !(-200..=200).contains(&y) {
            return -1;
        }
        *point = (x, y);
    }
    for i in 0..v {
        if points[..i].contains(&points[i]) { return -1; }
    }
    for vertex in boundary.iter_mut().take(bcount) {
        let raw = input[cursor]; cursor += 1;
        if raw < 0 || raw >= vr { return -1; }
        *vertex = raw as usize;
    }
    if boundary[..bcount].iter().collect::<std::collections::HashSet<_>>().len() != bcount {
        return -1;
    }
    for i in 0..bcount {
        let a = boundary[i]; let b = boundary[(i + 1) % bcount];
        for &c in &boundary[..bcount] {
            if c != a && c != b && orient(&points, a, b, points[c]) <= 0 { return -1; }
        }
    }
    for vertex in 0..v {
        if !boundary[..bcount].contains(&vertex) {
            for i in 0..bcount {
                if orient(&points, boundary[i], boundary[(i + 1) % bcount], points[vertex]) <= 0 { return -1; }
            }
        }
    }

    let mut area_sum = 0_i64;
    for f in 0..tcount {
        for e in 0..3 {
            let raw = input[cursor]; cursor += 1;
            if raw < 0 || raw >= vr { return -1; }
            faces[f][e] = raw as usize;
        }
        let face = faces[f];
        if face[0] == face[1] || face[1] == face[2] || face[2] == face[0]
            || orient(&points, face[0], face[1], points[face[2]]) <= 0 { return -1; }
        for vertex in face { used[vertex] = true; }
        area_sum += orient(&points, face[0], face[1], points[face[2]]);
        for prior in &faces[..f] {
            if face.iter().all(|vertex| prior.contains(vertex)) { return -1; }
        }
    }
    if used[..v].iter().any(|value| !value) { return -1; }
    let mut polygon_area = 0_i64;
    for i in 0..bcount {
        let a = points[boundary[i]]; let b = points[boundary[(i + 1) % bcount]];
        polygon_area += a.0 * b.1 - a.1 * b.0;
    }
    if polygon_area <= 0 || polygon_area != area_sum { return -1; }
    for f in 0..tcount { for e in 0..3 {
        let (a,b)=(faces[f][e],faces[f][(e+1)%3]);
        let first_copy=!(0..=f).any(|g| (0..3).any(|ge| {
            !(g==f && ge>=e) && same_edge(a,b,faces[g][ge],faces[g][(ge+1)%3])
        }));
        if !first_copy { continue; }
        for vertex in 0..v {
            if vertex!=a && vertex!=b && on_segment(&points,a,b,vertex) { return -1; }
        }
        for g in f..tcount { for ge in 0..3 {
            if g==f && ge<=e { continue; }
            let (c,d)=(faces[g][ge],faces[g][(ge+1)%3]);
            if a==c || a==d || b==c || b==d { continue; }
            if segments_intersect(&points,a,b,c,d) { return -1; }
        }}
    }}
    for i in 0..bcount {
        let a = boundary[i]; let b = boundary[(i + 1) % bcount];
        let owners = faces[..tcount].iter().map(|face| (0..3).filter(|&e| same_edge(a,b,face[e],face[(e+1)%3])).count()).sum::<usize>();
        if owners != 1 { return -1; }
    }
    for f in 0..tcount { for e in 0..3 {
        let (a,b)=(faces[f][e],faces[f][(e+1)%3]);
        let boundary_edge=(0..bcount).any(|i| same_edge(a,b,boundary[i],boundary[(i+1)%bcount]));
        let mut owners=0; let mut other=-1_i64; let mut first=(usize::MAX,usize::MAX);
        for g in 0..tcount { for ge in 0..3 {
            if same_edge(a,b,faces[g][ge],faces[g][(ge+1)%3]) {
                let directed=(faces[g][ge],faces[g][(ge+1)%3]);
                if owners==0 { first=directed; }
                else if directed.0!=first.1 || directed.1!=first.0 { return -1; }
                owners+=1;
                if g!=f { other=g as i64; }
            }
        }}
        if owners != (if boundary_edge {1} else {2}) { return -1; }
        if !boundary_edge { neighbors[f][e]=other; }
    }}
    for &choice in &input[cursor..cursor+k] { if !(0..=1).contains(&choice) { return -1; } }
    for i in 0..bcount {
        if orient(&points,boundary[i],boundary[(i+1)%bcount],(px,py))<=0 { return -1; }
    }
    let containing=(0..tcount).filter(|&f| {
        let z=faces[f]; orient(&points,z[0],z[1],(px,py))>0
            && orient(&points,z[1],z[2],(px,py))>0 && orient(&points,z[2],z[0],(px,py))>0
    }).count();
    if containing!=1 { return -1; }

    let mut face=start; let mut steps=0; let mut choice_index=0; let mut trace=(face+1) as i64;
    let mut predicates=0_i64; let status;
    loop {
        let z=faces[face]; let edges=[(z[0],z[1]),(z[1],z[2]),(z[2],z[0])];
        let mut eligible=[0_usize;3]; let mut count=0;
        for (edge,(a,b)) in edges.into_iter().enumerate() {
            predicates+=1;
            if orient(&points,a,b,(px,py))<0 { eligible[count]=edge; count+=1; }
        }
        if count==0 { status=0; break; }
        if steps==cap as usize { status=2; break; }
        let selected=if count==1 { eligible[0] } else if count==2 {
            if choice_index==k { status=1; break; }
            let selected=eligible[input[cursor+choice_index] as usize]; choice_index+=1; selected
        } else { return -1; };
        face=neighbors[face][selected] as usize;
        steps+=1; trace=trace*9+(face+1) as i64;
    }
    (trace*40+predicates)*3+status
}
