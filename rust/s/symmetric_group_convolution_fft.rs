// Uncompiled research draft; allocation and invariant handling need verification.
#[path = "symmetric_group_convolution_fft_plan.rs"]
mod plan;
#[path = "symmetric_group_convolution_fft_forward.rs"]
mod forward;
#[path = "symmetric_group_convolution_fft_inverse.rs"]
mod inverse;

enum DraftError { Allocation, Invariant }

fn try_capacity<T>(capacity: usize) -> Result<Vec<T>, DraftError> {
    let mut values = Vec::new();
    values.try_reserve_exact(capacity).map_err(|_| DraftError::Allocation)?;
    Ok(values)
}

fn try_zeros(length: usize) -> Result<Vec<i64>, DraftError> {
    let mut values = try_capacity(length)?;
    values.resize(length,0);
    Ok(values)
}

fn calculate(n: usize, a: &[i64], b: &[i64]) -> Result<Vec<i64>, DraftError> {
    let levels = plan::make_levels(n)?;
    let left = forward::forward(&levels,n,a)?;
    let right = forward::forward(&levels,n,b)?;
    let mut products = Vec::new();
    products.try_reserve_exact(levels[n].len()).map_err(|_| DraftError::Allocation)?;
    for (shape,rep) in levels[n].iter().enumerate() {
        let d = rep.basis.len();
        let mut block = Vec::new();
        block.try_reserve_exact(d*d).map_err(|_| DraftError::Allocation)?;
        block.resize(d*d,0);
        for row in 0..d {
            for inner in 0..d {
                for col in 0..d {
                    let slot = row*d+col;
                    block[slot] = (block[slot]+left[shape][row*d+inner]*right[shape][inner*d+col])%plan::MODULUS;
                }
            }
        }
        products.push(block);
    }
    inverse::inverse(&levels,n,&products)
}

#[no_mangle]
pub unsafe extern "C" fn symmetric_group_convolution_fft(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > 725_762 { return -1; }
    // Limit the raw ABI access to the validated caller-supplied frame.
    let values = std::slice::from_raw_parts(input,length);
    if !(1..=9).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    let count = plan::FACTORIALS[n];
    if length != 1+2*count || values[1..].iter().any(|&x| !(0..plan::MODULUS).contains(&x)) { return -1; }
    if output.is_null() || capacity < 4*count { return -2; }
    let result = match calculate(n,&values[1..1+count],&values[1+count..]) {
        Ok(value) => value,
        Err(DraftError::Allocation) => return -3,
        Err(DraftError::Invariant) => return -4,
    };
    let output = std::slice::from_raw_parts_mut(output,4*count);
    for (bytes,value) in output.chunks_exact_mut(4).zip(result) {
        bytes.copy_from_slice(&(value as u32).to_le_bytes());
    }
    (4*count) as i64
}
