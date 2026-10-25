fn valid_box(v: &[i64], at: usize) -> bool {
    for d in 0..4 { if !(-8..=8).contains(&v[at+d]) || !(-8..=8).contains(&v[at+4+d]) || v[at+d] >= v[at+4+d] { return false; } }
    true
}
fn volume_at(v: &[i64], at: usize) -> i64 { let mut p=1;for d in 0..4{p*=v[at+4+d]-v[at+d];}p }
fn union_volume(v: &[i64], left: usize, right: usize) -> i64 { let mut p=1;for d in 0..4{p*=v[left+4+d].max(v[right+4+d])-v[left+d].min(v[right+d]);}p }
fn penalty(v:&[i64],seed:usize,entry:usize)->i64{union_volume(v,seed,entry)-volume_at(v,seed)}

#[no_mangle]
pub unsafe extern "C" fn versabench_dbms_partition_entries(raw:*const i64,length:usize)->i64{
    if raw.is_null()||length<1||length>74{return -1;}let v=unsafe{std::slice::from_raw_parts(raw,length)};
    if !(2..=8).contains(&v[0]){return -1;}let fan=v[0] as usize;let count=fan+1;if length!=1+8*count{return -1;}
    for i in 0..count{if !valid_box(v,1+8*i){return -1;}}
    let(mut seed_a,mut seed_b)=(0usize,1usize);let mut largest=union_volume(v,1,9);
    for i in 0..count{for j in i+1..count{let candidate=union_volume(v,1+8*i,1+8*j);if candidate>largest{largest=candidate;seed_a=i;seed_b=j;}}}
    let(a_at,b_at)=(1+8*seed_a,1+8*seed_b);let(mut size_a,mut size_b)=(1usize,1usize);let mut mask=1i64<<seed_a;
    for i in 0..count{if i==seed_a||i==seed_b{continue;}let at=1+8*i;
        if size_a<fan&&size_b<fan{if penalty(v,a_at,at)<penalty(v,b_at,at){mask|=1i64<<i;size_a+=1;}else{size_b+=1;}}
        else if size_a>=fan&&size_b<fan{size_b+=1;}else if size_b>=fan&&size_a<fan{mask|=1i64<<i;size_a+=1;}else{return -1;}
    }
    mask
}
