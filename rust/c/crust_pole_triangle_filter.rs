const MAX_FACETS: usize = 16;
const MAX_VERTICES: i64 = 12;
fn put_i64(out:&mut [u8],word:usize,value:i64){out[word*8..word*8+8].copy_from_slice(&value.to_le_bytes());}

#[no_mangle]
pub unsafe extern "C" fn crust_pole_triangle_filter(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||!(3..=51).contains(&length){return -1;}
    let values=std::slice::from_raw_parts(input,length);let(ns0,np0,nf0)=(values[0],values[1],values[2]);
    if !(3..=8).contains(&ns0)||!(1..=4).contains(&np0)||ns0+np0>MAX_VERTICES||!(0..=16).contains(&nf0)||length!=3+3*nf0 as usize{return -1;}
    let ns=ns0 as usize;let total=(ns0+np0) as usize;let nf=nf0 as usize;let mut facets=[[0i64;3];MAX_FACETS];let mut count=0usize;
    for i in 0..nf{let mut tri=[values[3+3*i],values[4+3*i],values[5+3*i]];if tri.iter().any(|&v|v<0||v>=total as i64)||tri[0]==tri[1]||tri[0]==tri[2]||tri[1]==tri[2]{return -1;}if tri.iter().any(|&v|v>=ns as i64){continue;}tri.sort_unstable();if !facets[..count].contains(&tri){facets[count]=tri;count+=1;}}
    facets[..count].sort_unstable();let bytes=(1+3*count)*8;if output.is_null()||capacity<bytes{return -2;}let out=std::slice::from_raw_parts_mut(output,bytes);put_i64(out,0,count as i64);let mut at=1;for tri in &facets[..count]{for &v in tri{put_i64(out,at,v);at+=1;}}bytes as i64
}
