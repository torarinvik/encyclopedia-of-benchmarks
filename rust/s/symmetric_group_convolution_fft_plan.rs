// Uncompiled research draft: subgroup representation planning only.
use super::{try_capacity, DraftError};

pub const MODULUS: i64 = 998_244_353;
pub type Shape = [u8; 9];
pub type Tableau = [u8; 9];
pub const FACTORIALS: [usize; 10] = [1,1,2,6,24,120,720,5040,40320,362880];

pub fn power(mut base: i64, mut exponent: i64) -> i64 {
    let mut result = 1;
    while exponent != 0 {
        if exponent & 1 != 0 { result = result*base % MODULUS; }
        base = base*base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn enumerate(n: usize, next: usize, shape: &mut Shape, tableau: &mut Tableau,
             bases: &mut Vec<(Shape, Vec<Tableau>)>) -> Result<(), DraftError> {
    if next == n {
        let index = if let Some(index) = bases.iter().position(|(key, _)| key == shape) {
            index
        } else {
            bases.try_reserve(1).map_err(|_| DraftError::Allocation)?;
            bases.push((*shape, Vec::new()));
            bases.len()-1
        };
        bases[index].1.try_reserve(1).map_err(|_| DraftError::Allocation)?;
        bases[index].1.push(*tableau);
        return Ok(());
    }
    for row in 0..n {
        if row > 0 && shape[row] >= shape[row-1] { continue; }
        let col = shape[row];
        tableau[next] = row as u8*9+col;
        shape[row] += 1;
        let result = enumerate(n,next+1,shape,tableau,bases);
        shape[row] -= 1;
        result?;
        if col == 0 { break; }
    }
    Ok(())
}

fn tableau_order(a: &Tableau, b: &Tableau, n: usize) -> std::cmp::Ordering {
    for i in (0..n).rev() {
        let comparison = a[i].cmp(&b[i]);
        if comparison != std::cmp::Ordering::Equal { return comparison; }
    }
    std::cmp::Ordering::Equal
}

#[derive(Clone)]
pub struct Column {
    pub diagonal: i64,
    pub partner: Option<(usize, i64)>,
}

pub struct Embedding {
    pub child: usize,
    pub offset: usize,
    pub width: usize,
}

pub struct Representation {
    pub shape: Shape,
    pub basis: Vec<Tableau>,
    pub adjacent: Vec<Vec<Column>>,
    pub restrictions: Vec<Embedding>,
}

fn representation_plan(n: usize) -> Result<Vec<Representation>, DraftError> {
    let mut bases = Vec::new();
    enumerate(n,0,&mut [0;9],&mut [0;9],&mut bases)?;
    bases.sort_unstable_by(|a, b| a.0.cmp(&b.0));
    let mut result = try_capacity(bases.len())?;
    for (shape,mut basis) in bases {
        basis.sort_unstable_by(|a,b| tableau_order(a,b,n));
        let mut adjacent = try_capacity(n-1)?;
        for label in 0..n-1 {
            let mut columns = try_capacity(basis.len())?;
            for tableau in &basis {
                let first = tableau[label] as i64;
                let second = tableau[label+1] as i64;
                let distance = second%9-second/9-first%9+first/9;
                if distance == 0 { return Err(DraftError::Invariant); }
                let diagonal = power((distance+MODULUS)%MODULUS,MODULUS-2);
                let partner = if distance.abs() == 1 { None } else {
                    let mut swapped = *tableau;
                    swapped.swap(label,label+1);
                    let index = basis.binary_search_by(|candidate| tableau_order(candidate,&swapped,n)).map_err(|_| DraftError::Invariant)?;
                    let coefficient = if distance > 0 { 1 } else { (1-diagonal*diagonal%MODULUS+MODULUS)%MODULUS };
                    Some((index,coefficient))
                };
                columns.push(Column { diagonal, partner });
            }
            adjacent.push(columns);
        }
        result.push(Representation { shape,basis,adjacent,restrictions:Vec::new() });
    }
    Ok(result)
}

pub fn make_levels(n: usize) -> Result<Vec<Vec<Representation>>, DraftError> {
    if !(1..=9).contains(&n) { return Err(DraftError::Invariant); }
    let mut levels = try_capacity(n+1)?;
    levels.push(Vec::new());
    for degree in 1..=n { levels.push(representation_plan(degree)?); }
    for degree in 2..=n {
        let (earlier, later) = levels.split_at_mut(degree);
        let children = &earlier[degree-1];
        for parent in &mut later[0] {
            let mut start = 0;
            while start < parent.basis.len() {
                let corner = parent.basis[start][degree-1];
                let mut end = start+1;
                while end < parent.basis.len() && parent.basis[end][degree-1] == corner { end += 1; }
                let mut child_shape = parent.shape;
                child_shape[(corner/9) as usize] -= 1;
                let child = children.iter().position(|rep| rep.shape == child_shape).ok_or(DraftError::Invariant)?;
                if children[child].basis.len() != end-start { return Err(DraftError::Invariant); }
                for index in 0..end-start {
                    if parent.basis[start+index][..degree-1] != children[child].basis[index][..degree-1] { return Err(DraftError::Invariant); }
                }
                parent.restrictions.try_reserve(1).map_err(|_| DraftError::Allocation)?;
                parent.restrictions.push(Embedding { child, offset:start, width:end-start });
                start = end;
            }
        }
    }
    Ok(levels)
}
