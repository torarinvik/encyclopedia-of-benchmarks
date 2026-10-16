fn put_f64(output: &mut [u8], offset: &mut usize, value: f64) {
    output[*offset..*offset + 8].copy_from_slice(&value.to_le_bytes());
    *offset += 8;
}
fn put_i64(output: &mut [u8], offset: &mut usize, value: i64) {
    output[*offset..*offset + 8].copy_from_slice(&value.to_le_bytes());
    *offset += 8;
}

#[no_mangle]
pub unsafe extern "C" fn correlation_matrix_analysis(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 22 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] != 4 || !(2..=5).contains(&values[1]) { return -1; }
    let p = values[1] as usize;
    if length != 2 + 4 * p || values[2..].iter().any(|&x| !(-1000..=1000).contains(&x)) { return -1; }
    for col in 0..p { if (1..4).all(|row| values[2 + row * p + col] == values[2 + col]) { return -1; } }
    let output_bytes = 32 * p * p + 48;
    if output.is_null() || capacity < output_bytes { return -2; }
    let out = std::slice::from_raw_parts_mut(output, output_bytes);
    let mut means = [0.0f64; 5];
    for col in 0..p { for row in 0..4 { means[col] += values[2 + row * p + col] as f64; } means[col] /= 4.0; }
    let mut corr = [0.0f64; 25]; let mut raw = [1.0f64; 25];
    let mut bonf = [1.0f64; 25]; let mut fdr = [1.0f64; 25];
    for i in 0..p { corr[i * p + i] = 1.0; }
    let mut pair_i = [0usize; 10]; let mut pair_j = [0usize; 10]; let mut pair_p = [0.0f64; 10]; let mut count = 0usize;
    for j in 1..p { for i in 0..j {
        let mut cross = 0.0; let mut sum_i = 0.0; let mut sum_j = 0.0;
        for row in 0..4 {
            let dx = values[2 + row * p + i] as f64 - means[i];
            let dy = values[2 + row * p + j] as f64 - means[j];
            cross += dx * dy; sum_i += dx * dx; sum_j += dy * dy;
        }
        let r = cross / (sum_i * sum_j).sqrt(); let pv = 1.0 - r.abs();
        corr[i * p + j] = r; corr[j * p + i] = r;
        raw[i * p + j] = pv; raw[j * p + i] = pv;
        pair_i[count] = i; pair_j[count] = j; pair_p[count] = pv; count += 1;
    }}
    for k in 0..count { let value = (pair_p[k] * count as f64).min(1.0); let i=pair_i[k];let j=pair_j[k];bonf[i*p+j]=value;bonf[j*p+i]=value; }
    let mut order=[0usize;10];for k in 0..count { order[k]=k; }
    for k in 1..count { let value=order[k];let mut at=k;while at>0&&pair_p[order[at-1]]>pair_p[value]{order[at]=order[at-1];at-=1;}order[at]=value; }
    let mut running=1.0;for pos in (0..count).rev(){let mut adj=pair_p[order[pos]]*count as f64/(pos+1) as f64;if adj>1.0{adj=1.0;}if adj<running{running=adj;}let k=order[pos];let i=pair_i[k];let j=pair_j[k];fdr[i*p+j]=running;fdr[j*p+i]=running;}
    let mut sr=0i64;let mut sb=0i64;let mut sf=0i64;for k in 0..count{let i=pair_i[k];let j=pair_j[k];if pair_p[k]<0.05{sr+=1;}if bonf[i*p+j]<0.05{sb+=1;}if fdr[i*p+j]<0.05{sf+=1;}}
    let mut offset=0usize;for matrix in [&corr,&raw,&bonf,&fdr]{for i in 0..p*p{put_f64(out,&mut offset,matrix[i]);}}
    for x in [4,p as i64,0,sr,sb,sf]{put_i64(out,&mut offset,x);}
    offset as i64
}
