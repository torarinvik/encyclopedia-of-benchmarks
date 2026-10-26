fn put_i64(dst:&mut [u8],value:i64){dst[..8].copy_from_slice(&value.to_le_bytes());}

#[no_mangle]
pub unsafe extern "C" fn counting_triangles_stream_reservoir(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<6||length>114{return -1;}
    let a=std::slice::from_raw_parts(input,length);let n0=a[0];let m0=a[1];
    if !(2..=8).contains(&n0)||!(1..=28).contains(&m0)||length!=2+4*m0 as usize{return -1;}
    let n=n0 as usize;let m=m0 as usize;let mut seen=[[false;8];8];let mut edges=[[0i64;2];28];
    for i in 0..m{let u=a[2+2*i];let v=a[3+2*i];if u<0||v<=u||v>=n0||seen[u as usize][v as usize]{return -1;}seen[u as usize][v as usize]=true;seen[v as usize][u as usize]=true;edges[i]=[u,v];}
    let base=2+2*m;for t in 1..=m{for s in 0..2{let r=a[base+2*(t-1)+s];if r<0||r>=t as i64{return -1;}}}
    let mut slots=[[-1i64,-1i64];2];let mut staged=[0i64;112];let mut at=0usize;
    for t in 1..=m{for s in 0..2{if a[base+2*(t-1)+s]==0{slots[s]=edges[t-1];}}for slot in slots{staged[at]=slot[0];at+=1;staged[at]=slot[1];at+=1;}}
    let bytes=16*m;if output.is_null()||capacity<bytes{return -2;}let dst=std::slice::from_raw_parts_mut(output,bytes);for i in 0..at{put_i64(&mut dst[8*i..],staged[i]);}bytes as i64
}
