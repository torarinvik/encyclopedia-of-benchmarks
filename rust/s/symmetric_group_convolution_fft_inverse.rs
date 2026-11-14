// Uncompiled transpose-recursion inverse-transform research draft.
use super::forward::{next_permutation, permutation_rank, Block, Blocks};
use super::plan::{power, Column, Representation, FACTORIALS, MODULUS};
use super::{try_capacity, try_zeros, DraftError};

fn invariant_diagonal(rep: &Representation) -> Result<Vec<i64>, DraftError> {
    let d = rep.basis.len();
    let mut weights = try_zeros(d)?;
    weights.fill(-1);
    let mut queue = try_capacity(d)?;
    for start in 0..d {
        if weights[start] != -1 { continue; }
        weights[start] = 1;
        queue.clear(); queue.push(start);
        let mut head = 0;
        while head < queue.len() {
            let source = queue[head]; head += 1;
            for generator in &rep.adjacent {
                if let Some((target,forward)) = generator[source].partner {
                    let (back_target,backward) = generator[target].partner.ok_or(DraftError::Invariant)?;
                    if back_target != source || forward == 0 || backward == 0 { return Err(DraftError::Invariant); }
                    let candidate = weights[source]*backward%MODULUS*power(forward,MODULUS-2)%MODULUS;
                    if weights[target] == -1 { weights[target] = candidate; queue.push(target); }
                    else if weights[target] != candidate { return Err(DraftError::Invariant); }
                }
            }
        }
    }
    Ok(weights)
}

fn apply_left_transpose(generator: &[Column], input: &[i64]) -> Result<Block, DraftError> {
    let d = generator.len();
    let mut result = try_zeros(d*d)?;
    for (source,column) in generator.iter().enumerate() {
        for col in 0..d {
            let mut value = column.diagonal*input[source*d+col]%MODULUS;
            if let Some((target,coefficient)) = column.partner {
                value = (value+coefficient*input[target*d+col])%MODULUS;
            }
            result[source*d+col] = value;
        }
    }
    Ok(result)
}

fn transpose_forward(levels: &[Vec<Representation>], n: usize, gradients: &Blocks) -> Result<Vec<i64>, DraftError> {
    if n == 1 {
        let mut output = try_zeros(1)?;
        output[0] = gradients[0][0];
        return Ok(output);
    }
    let reps = &levels[n];
    let mut output = try_zeros(FACTORIALS[n])?;
    for j in 0..n {
        let mut child: Blocks = try_capacity(levels[n-1].len())?;
        for rep in &levels[n-1] { child.push(try_zeros(rep.basis.len().pow(2))?); }
        for (shape,rep) in reps.iter().enumerate() {
            let d = rep.basis.len();
            let mut block = try_capacity(gradients[shape].len())?;
            block.extend_from_slice(&gradients[shape]);
            for generator in j..n-1 { block = apply_left_transpose(&rep.adjacent[generator],&block)?; }
            for generator in (j..n.saturating_sub(2)).rev() {
                block = apply_left_transpose(&rep.adjacent[generator],&block)?;
            }
            for entry in &rep.restrictions {
                for row in 0..entry.width {
                    for col in 0..entry.width {
                        let target = row*entry.width+col;
                        child[entry.child][target] = (child[entry.child][target]
                            + block[(entry.offset+row)*d+entry.offset+col])%MODULUS;
                    }
                }
            }
        }
        let restricted = transpose_forward(levels,n-1,&child)?;
        let mut h = [0usize;9];
        for (index,value) in h[..n-1].iter_mut().enumerate() { *value = index; }
        let mut index = 0;
        loop {
            let mut g = h; g[n-1] = n-1;
            for value in &mut g[..n] {
                if *value == j { *value = n-1; }
                else if *value == n-1 { *value = j; }
            }
            output[permutation_rank(&g[..n])] = restricted[index];
            index += 1;
            if !next_permutation(&mut h[..n-1]) { break; }
        }
    }
    Ok(output)
}

pub fn inverse(levels: &[Vec<Representation>], n: usize, blocks: &Blocks) -> Result<Vec<i64>, DraftError> {
    if n == 1 {
        let mut result = try_zeros(1)?;
        result[0] = blocks[0][0];
        return Ok(result);
    }
    let inverse_order = power(FACTORIALS[n] as i64,MODULUS-2);
    let mut weighted = try_capacity(levels[n].len())?;
    for (shape,rep) in levels[n].iter().enumerate() {
        let d = rep.basis.len();
        let diagonal = invariant_diagonal(rep)?;
        let mut inverse_diagonal = try_capacity(d)?;
        for &value in &diagonal { inverse_diagonal.push(power(value,MODULUS-2)); }
        let mut block = try_zeros(d*d)?;
        for row in 0..d {
            for col in 0..d {
                let mut value = blocks[shape][row*d+col]*d as i64%MODULUS;
                value = value*inverse_order%MODULUS;
                value = value*diagonal[row]%MODULUS;
                block[row*d+col] = value*inverse_diagonal[col]%MODULUS;
            }
        }
        weighted.push(block);
    }
    transpose_forward(levels,n,&weighted)
}
