const MAX_CELLS: usize = 1089;
fn put_i64(out: &mut [u8], pos: &mut usize, value: i64) { out[*pos..*pos+8].copy_from_slice(&value.to_le_bytes()); *pos += 8; }
#[no_mangle]
pub unsafe extern "C" fn min_cost_string_conversion(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > 70 { return -1; }
    let v=std::slice::from_raw_parts(input,length);let sn=v[0];if !(0..=32).contains(&sn){return -1;}let src=sn as usize;let dp0=1+src;if dp0>=length{return -1;}let dn=v[dp0];if !(0..=32).contains(&dn){return -1;}let dst=dn as usize;if length!=6+src+dst{return -1;}let tp=dp0+1;let cp=tp+dst;
    if v[1..1+src].iter().any(|x|!(0..=127).contains(x))||v[tp..tp+dst].iter().any(|x|!(0..=127).contains(x))||v[cp..].iter().any(|x|!(-1000..=1000).contains(x)){return -1;}
    let (cc,rc,dc,ic)=(v[cp],v[cp+1],v[cp+2],v[cp+3]);let rows=src+1;let cols=dst+1;let cells=rows*cols;
    let mut costs=[0i64;MAX_CELLS];let mut codes=[0i64;MAX_CELLS];let mut ca=[0i64;MAX_CELLS];let mut cb=[0i64;MAX_CELLS];
    for j in 1..cols{let x=j;costs[x]=costs[x-1]+ic;codes[x]=4;cb[x]=v[tp+j-1];}
    for i in 1..rows{let x=i*cols;costs[x]=costs[x-cols]+dc;codes[x]=3;ca[x]=v[i];}
    for i in 1..rows{for j in 1..cols{let x=i*cols+j;let a=v[i];let b=v[tp+j-1];let same=a==b;let mut best=costs[x-cols-1]+if same{cc}else{rc};let(mut op,mut aa,mut bb)=if same{(1,a,0)}else{(2,a,b)};let deletion=costs[x-cols]+dc;if deletion<best{best=deletion;op=3;aa=a;bb=0;}let insertion=costs[x-1]+ic;if insertion<best{best=insertion;op=4;aa=0;bb=b;}costs[x]=best;codes[x]=op;ca[x]=aa;cb[x]=bb;}}
    let needed=32+cells*32;if output.is_null()||capacity<needed{return -2;}let out=std::slice::from_raw_parts_mut(output,needed);let mut p=0;put_i64(out,&mut p,rows as i64);put_i64(out,&mut p,cols as i64);for x in 0..cells{put_i64(out,&mut p,costs[x]);}put_i64(out,&mut p,rows as i64);put_i64(out,&mut p,cols as i64);for x in 0..cells{put_i64(out,&mut p,codes[x]);put_i64(out,&mut p,ca[x]);put_i64(out,&mut p,cb[x]);}p as i64
}
