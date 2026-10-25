const MAX_NODES: usize = 8;
const MAX_DEGREE: usize = 4;

#[no_mangle]
pub unsafe extern "C" fn olden_em3d(input: *const f64, input_length: usize,
    output: *mut f64, output_capacity: usize) -> i64 {
    if input.is_null() || input_length < 2 { return -1; }
    let rn = unsafe { *input }; let rd = unsafe { *input.add(1) };
    if !(rn >= 1.0 && rn <= MAX_NODES as f64) || rn.fract() != 0.0 ||
       !(rd >= 1.0 && rd <= MAX_DEGREE as f64) || rd.fract() != 0.0 { return -1; }
    let n = rn as usize; let degree = rd as usize; let edges = n * degree;
    if input_length != 2 + 2*n + 4*edges { return -1; }
    let mut electric = [0.0_f64; MAX_NODES]; let mut magnetic = [0.0_f64; MAX_NODES];
    let mut offset = 2;
    for i in 0..n { let value = unsafe { *input.add(offset+i) }; if !(0.0..=1.0).contains(&value) { return -1; } electric[i] = value; }
    offset += n;
    for i in 0..n { let value = unsafe { *input.add(offset+i) }; if !(0.0..=1.0).contains(&value) { return -1; } magnetic[i] = value; }
    offset += n;
    let e_neighbors = offset; offset += edges;
    let e_coefficients = offset; offset += edges;
    let h_neighbors = offset; offset += edges;
    let h_coefficients = offset;
    for i in 0..edges {
        let en = unsafe { *input.add(e_neighbors+i) }; let hn = unsafe { *input.add(h_neighbors+i) };
        let ec = unsafe { *input.add(e_coefficients+i) }; let hc = unsafe { *input.add(h_coefficients+i) };
        if !en.is_finite() || en.fract()!=0.0 || en < 0.0 || en >= n as f64 || !hn.is_finite() || hn.fract()!=0.0 || hn < 0.0 || hn >= n as f64 || !(0.0..=1.0).contains(&ec) || !(0.0..=1.0).contains(&hc) { return -1; }
        let start = (i / degree) * degree;
        for j in start..i { if unsafe { *input.add(e_neighbors+j) } == en || unsafe { *input.add(h_neighbors+j) } == hn { return -1; } }
    }
    if output.is_null() || output_capacity < 2*n { return -2; }
    for node in 0..n {
        let mut current = electric[node]; let base = node * degree;
        for edge in 0..degree { let coefficient = base + (edge & !1); let neighbor = unsafe { *input.add(e_neighbors+base+edge) as usize }; current -= unsafe { *input.add(e_coefficients+coefficient) } * magnetic[neighbor]; }
        electric[node] = current;
    }
    for node in 0..n {
        let mut current = magnetic[node]; let base = node * degree;
        for edge in 0..degree { let coefficient = base + (edge & !1); let neighbor = unsafe { *input.add(h_neighbors+base+edge) as usize }; current -= unsafe { *input.add(h_coefficients+coefficient) } * electric[neighbor]; }
        magnetic[node] = current;
    }
    for i in 0..n { unsafe { *output.add(i) = electric[i]; *output.add(n+i) = magnetic[i]; } }
    (2*n) as i64
}
