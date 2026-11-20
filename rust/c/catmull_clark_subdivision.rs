const MAX_V: usize = 24;
const MAX_F: usize = 8;
const MAX_D: usize = 8;
const MAX_E: usize = 32;
const MAX_IN: usize = 122;
const MAX_OUT: usize = 386;

#[derive(Clone, Copy, Default)]
struct Edge { u: usize, v: usize, f0: usize, f1: usize, uses: usize }

fn integer(value: f64, low: usize, high: usize) -> Option<usize> {
    if !value.is_finite() || value.fract() != 0.0 || value < low as f64 || value > high as f64 { None }
    else { Some(value as usize) }
}
fn mean(values: &[f64]) -> f64 {
    let scale = values.iter().fold(0.0_f64, |s, &x| s.max(x.abs()));
    if scale == 0.0 { return 0.0; }
    (values.iter().map(|x| *x / scale).sum::<f64>() / values.len() as f64) * scale
}
fn average4(a: f64, b: f64, c: f64, d: f64) -> f64 {
    let scale = a.abs().max(b.abs()).max(c.abs()).max(d.abs());
    if scale == 0.0 { 0.0 } else { ((a/scale+b/scale+c/scale+d/scale)*0.25)*scale }
}

#[no_mangle]
pub unsafe extern "C" fn catmull_clark_subdivision(
    input: *const f64, length: usize, output: *mut f64, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_IN).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|value| !value.is_finite()) { return -1; }
    let Some(nv) = integer(values[0], 0, MAX_V) else { return -1; };
    let Some(nf) = integer(values[1], 0, MAX_F) else { return -1; };
    if (nv == 0 || nf == 0) && !(nv == 0 && nf == 0 && length == 2) { return -1; }

    let mut x = [0.0_f64; MAX_V];
    let mut y = [0.0_f64; MAX_V];
    let mut degree = [0_usize; MAX_F];
    let mut face = [[0_usize; MAX_D]; MAX_F];
    let mut pos = 2;
    if pos + 2 * nv > length { return -1; }
    for v in 0..nv { x[v] = values[pos]; y[v] = values[pos + 1]; pos += 2; }

    let mut edges = [Edge::default(); MAX_E];
    let mut edge_count = 0;
    for f in 0..nf {
        if pos >= length { return -1; }
        let Some(d) = integer(values[pos], 3, MAX_D) else { return -1; };
        degree[f] = d; pos += 1;
        if pos + d > length { return -1; }
        for i in 0..d {
            let Some(v) = integer(values[pos], 0, nv.saturating_sub(1)) else { return -1; };
            if nv == 0 || face[f][..i].contains(&v) { return -1; }
            face[f][i] = v; pos += 1;
        }
        for i in 0..d {
            let a = face[f][i]; let b = face[f][(i + 1) % d];
            let (u, v) = (a.min(b), a.max(b));
            let mut found = None;
            for e in 0..edge_count { if edges[e].u == u && edges[e].v == v { found = Some(e); break; } }
            if let Some(e) = found {
                if edges[e].uses != 1 || edges[e].f0 == f { return -1; }
                edges[e].uses = 2; edges[e].f1 = f;
            } else {
                if edge_count == MAX_E { return -1; }
                edges[edge_count] = Edge { u, v, f0: f, f1: 0, uses: 1 };
                edge_count += 1;
            }
        }
    }
    if pos != length || edges[..edge_count].iter().any(|edge| edge.uses != 2) { return -1; }

    for v in 0..nv {
        let valence = edges[..edge_count].iter().filter(|e| e.u == v || e.v == v).count();
        let mut link_a = [0_usize; MAX_F]; let mut link_b = [0_usize; MAX_F]; let mut links = 0;
        for f in 0..nf { for i in 0..degree[f] { if face[f][i] == v {
            let a = face[f][(i + degree[f] - 1) % degree[f]];
            let b = face[f][(i + 1) % degree[f]];
            let key = (a.min(b), a.max(b));
            if (0..links).any(|j| (link_a[j].min(link_b[j]), link_a[j].max(link_b[j])) == key) { return -1; }
            link_a[links] = a; link_b[links] = b; links += 1;
        } } }
        if valence < 3 || links != valence { return -1; }
        let mut reached = [false; MAX_V]; reached[link_a[0]] = true;
        loop { let mut changed = false; for i in 0..links {
            if reached[link_a[i]] && !reached[link_b[i]] { reached[link_b[i]] = true; changed = true; }
            if reached[link_b[i]] && !reached[link_a[i]] { reached[link_a[i]] = true; changed = true; }
        } if !changed { break; } }
        let mut node_degree = [0_usize; MAX_V];
        for i in 0..links { node_degree[link_a[i]] += 1; node_degree[link_b[i]] += 1; }
        let mut nodes = 0;
        for u in 0..nv { if node_degree[u] != 0 { nodes += 1; if node_degree[u] != 2 || !reached[u] { return -1; } } }
        if nodes < 3 { return -1; }
    }

    for i in 1..edge_count { let item = edges[i]; let mut j = i;
        while j > 0 && (edges[j-1].u > item.u || (edges[j-1].u == item.u && edges[j-1].v > item.v)) { edges[j] = edges[j-1]; j -= 1; }
        edges[j] = item;
    }
    let mut face_x = [0.0_f64; MAX_F]; let mut face_y = [0.0_f64; MAX_F];
    for f in 0..nf { let mut vx=[0.0;MAX_D];let mut vy=[0.0;MAX_D];for i in 0..degree[f]{vx[i]=x[face[f][i]];vy[i]=y[face[f][i]];}face_x[f]=mean(&vx[..degree[f]]);face_y[f]=mean(&vy[..degree[f]]); }

    let mut staged = [0.0_f64; MAX_OUT]; let mut out = 0;
    let output_vertices = nv + edge_count + nf; let output_faces: usize = degree[..nf].iter().sum();
    staged[out]=output_vertices as f64;out+=1;staged[out]=output_faces as f64;out+=1;
    for v in 0..nv {
        let mut fxs=[0.0;MAX_F];let mut fys=[0.0;MAX_F];let mut rx=[0.0;MAX_F];let mut ry=[0.0;MAX_F];let mut nfi=0;let mut nei=0;
        for f in 0..nf { if face[f][..degree[f]].contains(&v) { fxs[nfi]=face_x[f];fys[nfi]=face_y[f];nfi+=1; } }
        for e in &edges[..edge_count] { if e.u==v||e.v==v {rx[nei]=mean(&[x[e.u],x[e.v]]);ry[nei]=mean(&[y[e.u],y[e.v]]);nei+=1;} }
        let fxa=mean(&fxs[..nfi]);let fya=mean(&fys[..nfi]);let rxa=mean(&rx[..nei]);let rya=mean(&ry[..nei]);
        let sx=x[v].abs().max(fxa.abs()).max(rxa.abs());let sy=y[v].abs().max(fya.abs()).max(rya.abs());
        staged[out]=if sx==0.0{0.0}else{((fxa/sx+2.0*rxa/sx+(nei as f64-3.0)*(x[v]/sx))/nei as f64)*sx};out+=1;
        staged[out]=if sy==0.0{0.0}else{((fya/sy+2.0*rya/sy+(nei as f64-3.0)*(y[v]/sy))/nei as f64)*sy};out+=1;
    }
    for e in &edges[..edge_count] { staged[out]=average4(x[e.u],x[e.v],face_x[e.f0],face_x[e.f1]);out+=1;staged[out]=average4(y[e.u],y[e.v],face_y[e.f0],face_y[e.f1]);out+=1; }
    for f in 0..nf { staged[out]=face_x[f];out+=1;staged[out]=face_y[f];out+=1; }
    for f in 0..nf { for i in 0..degree[f] { let v=face[f][i];let next=face[f][(i+1)%degree[f]];let prev=face[f][(i+degree[f]-1)%degree[f]];
        let en=edges[..edge_count].iter().position(|e|e.u==v.min(next)&&e.v==v.max(next)).unwrap_or(0);
        let ep=edges[..edge_count].iter().position(|e|e.u==v.min(prev)&&e.v==v.max(prev)).unwrap_or(0);
        staged[out]=v as f64;out+=1;staged[out]=(nv+en)as f64;out+=1;staged[out]=(nv+edge_count+f)as f64;out+=1;staged[out]=(nv+ep)as f64;out+=1;
    } }
    if out>MAX_OUT{return -1;}if output.is_null()||capacity<out{return -2;}std::ptr::copy_nonoverlapping(staged.as_ptr(),output,out);out as i64
}
