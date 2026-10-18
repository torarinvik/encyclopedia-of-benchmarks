const MAX_INPUT: usize = 6;
const MAX_ITERATIONS: usize = 256;
const QR_TOLERANCE: f64 = 1e-10;

fn dot(a: &[f64; 2], b: &[f64; 2]) -> f64 {
    let mut total = 0.0;
    for i in 0..2 { total += a[i] * b[i]; }
    total
}

fn qr(matrix: &[f64; 4]) -> Option<([f64; 4], [f64; 4])> {
    let mut q = [0.0; 4];
    let mut r = [0.0; 4];
    for column in 0..2 {
        let original = [matrix[column], matrix[2+column]];
        let mut residual = original;
        for previous in 0..column {
            let basis = [q[previous], q[2+previous]];
            let denominator = dot(&basis, &basis);
            if !denominator.is_finite() || denominator == 0.0 { return None; }
            let scalar = dot(&original, &basis) / denominator;
            if !scalar.is_finite() { return None; }
            for row in 0..2 {
                residual[row] -= scalar * basis[row];
                if !residual[row].is_finite() { return None; }
            }
        }
        let norm_squared = dot(&residual, &residual);
        if !norm_squared.is_finite() || norm_squared <= 0.0 { return None; }
        let norm = norm_squared.sqrt();
        if !norm.is_finite() || norm == 0.0 { return None; }
        for row in 0..2 {
            q[row*2+column] = residual[row] / norm;
            if !q[row*2+column].is_finite() { return None; }
        }
        for target in column..2 {
            let q_column = [q[column],q[2+column]];
            let matrix_column = [matrix[target],matrix[2+target]];
            r[column*2+target] = dot(&q_column,&matrix_column);
            if !r[column*2+target].is_finite() { return None; }
        }
    }
    Some((q,r))
}

#[no_mangle]
pub unsafe extern "C" fn qr_eigen_values(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT).contains(&input_length) { return -1; }
    let values=unsafe { std::slice::from_raw_parts(input,input_length) };
    if !values[0].is_finite() || values[0] != 2.0 || input_length != 5 { return -1; }
    let mut matrix=[0.0;4];
    for i in 0..4 {
        let x=values[i+1];
        if !x.is_finite() || !(-9.0..=9.0).contains(&x) || x.fract()!=0.0 { return -1; }
        matrix[i]=x;
    }
    if matrix[1]!=matrix[2] || matrix[1]==0.0 || matrix[0]==matrix[3] { return -1; }
    let mut last_eigenvalue=0.0;
    let mut iterations=0usize;
    while matrix[2].abs()>QR_TOLERANCE {
        if iterations>=MAX_ITERATIONS { return -1; }
        last_eigenvalue=matrix[3];
        let mut shifted=matrix;
        shifted[0]-=last_eigenvalue;shifted[3]-=last_eigenvalue;
        let (q,r)=match qr(&shifted){Some(pair)=>pair,None=>return -1};
        let mut updated=[0.0;4];
        for row in 0..2 { for column in 0..2 { for inner in 0..2 {
            updated[row*2+column]+=r[row*2+inner]*q[inner*2+column];
        }}}
        updated[0]+=last_eigenvalue;updated[3]+=last_eigenvalue;
        if updated.iter().any(|x|!x.is_finite()){return -1;}
        matrix=updated;iterations+=1;
    }
    let staged=[matrix[0],last_eigenvalue];
    if staged.iter().any(|x|!x.is_finite()){return -1;}
    if output.is_null()||output_capacity<2{return -2;}
    unsafe{*output=staged[0];*output.add(1)=staged[1];}
    2
}
