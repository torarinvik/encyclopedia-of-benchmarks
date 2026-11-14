// Uncompiled subgroup-chain forward-transform research draft.
use super::plan::{Column, Representation, FACTORIALS, MODULUS};
use super::{try_capacity, try_zeros, DraftError};

pub type Block = Vec<i64>;
pub type Blocks = Vec<Block>;

pub fn permutation_rank(permutation: &[usize]) -> usize {
    let mut rank = 0;
    for i in 0..permutation.len() {
        let smaller = permutation[i+1..].iter().filter(|&&value| value < permutation[i]).count();
        rank += smaller*FACTORIALS[permutation.len()-1-i];
    }
    rank
}

pub fn next_permutation(values: &mut [usize]) -> bool {
    if values.len() < 2 { return false; }
    let mut pivot = values.len()-1;
    while pivot > 0 && values[pivot-1] >= values[pivot] { pivot -= 1; }
    if pivot == 0 { return false; }
    let mut successor = values.len()-1;
    while values[successor] <= values[pivot-1] { successor -= 1; }
    values.swap(pivot-1,successor);
    values[pivot..].reverse();
    true
}

pub fn apply_left(generator: &[Column], input: &[i64]) -> Result<Block, DraftError> {
    let d = generator.len();
    let mut result = try_zeros(d*d)?;
    for (source,column) in generator.iter().enumerate() {
        for col in 0..d {
            let value = input[source*d+col];
            let diagonal = source*d+col;
            result[diagonal] = (result[diagonal]+column.diagonal*value)%MODULUS;
            if let Some((row,coefficient)) = column.partner {
                let partner = row*d+col;
                result[partner] = (result[partner]+coefficient*value)%MODULUS;
            }
        }
    }
    Ok(result)
}

pub fn forward(levels: &[Vec<Representation>], n: usize, input: &[i64]) -> Result<Blocks, DraftError> {
    if n == 1 {
        let mut block = try_capacity(1)?;
        block.push(input[0]);
        let mut output = try_capacity(1)?;
        output.push(block);
        return Ok(output);
    }
    let reps = &levels[n];
    let mut output: Blocks = try_capacity(reps.len())?;
    for rep in reps { output.push(try_zeros(rep.basis.len().pow(2))?); }
    for j in 0..n {
        let mut restricted = try_capacity(FACTORIALS[n-1])?;
        let mut h = [0usize;9];
        for (index, value) in h[..n-1].iter_mut().enumerate() { *value = index; }
        loop {
            let mut g = h;
            g[n-1] = n-1;
            for value in &mut g[..n] {
                if *value == j { *value = n-1; }
                else if *value == n-1 { *value = j; }
            }
            restricted.push(input[permutation_rank(&g[..n])]);
            if !next_permutation(&mut h[..n-1]) { break; }
        }
        let child = forward(levels,n-1,&restricted)?;
        for (shape,rep) in reps.iter().enumerate() {
            let d = rep.basis.len();
            let mut embedded = try_zeros(d*d)?;
            for entry in &rep.restrictions {
                for row in 0..entry.width {
                    for col in 0..entry.width {
                        embedded[(entry.offset+row)*d+entry.offset+col] =
                            child[entry.child][row*entry.width+col];
                    }
                }
            }
            for generator in j..n-1 { embedded = apply_left(&rep.adjacent[generator],&embedded)?; }
            for generator in (j..n.saturating_sub(2)).rev() {
                embedded = apply_left(&rep.adjacent[generator],&embedded)?;
            }
            for (slot,value) in output[shape].iter_mut().zip(embedded) {
                *slot = (*slot+value)%MODULUS;
            }
        }
    }
    Ok(output)
}
