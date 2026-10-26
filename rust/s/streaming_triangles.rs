fn put_i64(dst:&mut [u8],x:i64){dst[..8].copy_from_slice(&x.to_le_bytes());}
fn power(base:i64,exp:usize)->i64{let mut r=1;for _ in 0..exp{r*=base;}r}
fn make_wedge(a:(i64,i64),b:(i64,i64))->Option<(i64,i64)>{let mut common=None;for x in [a.0,a.1]{for y in [b.0,b.1]{if x==y{common=Some(x);}}}let c=common?;let x=if a.0==c{a.1}else{a.0};let y=if b.0==c{b.1}else{b.0};if x==y{None}else if x<y{Some((x,y))}else{Some((y,x))}}

#[no_mangle]
pub unsafe extern "C" fn streaming_triangles(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<10||length>340{return -1;}
    let a=std::slice::from_raw_parts(input,length);let n0=a[0];let m0=a[1];let se0=a[2];let sw0=a[3];
    if !(2..=8).contains(&n0)||!(1..=28).contains(&m0)||!(2..=4).contains(&se0)||!(1..=4).contains(&sw0){return -1;}
    let n=n0 as usize;let m=m0 as usize;let se=se0 as usize;let sw=sw0 as usize;let stride=2+2*sw;if length!=4+2*m+m*stride{return -1;}
    let mut edges=[(0i64,0i64);28];let mut seen=[[false;8];8];for i in 0..m{let u=a[4+2*i];let v=a[5+2*i];if u<0||v<=u||v>=n0||seen[u as usize][v as usize]{return -1;}seen[u as usize][v as usize]=true;seen[v as usize][u as usize]=true;edges[i]=(u,v);}
    let mut edge_res=[None::<usize>;4];let mut wedge_res=[None::<(i64,i64)>;4];let mut closed=[false;4];let mut total=0i64;let mut staged=[0i64;84];let mut at=0usize;let tape=4+2*m;
    for ti in 0..m{let t=ti+1;let (u,v)=edges[ti];for s in 0..sw{if wedge_res[s]==Some((u,v)){closed[s]=true;}}
        let rec=tape+ti*stride;let draw=a[rec];let slot0=a[rec+1];let lim=power(t as i64,se);let threshold=lim-power((t-1) as i64,se);if draw<0||draw>=lim{return -1;}let update=draw<threshold;let mut fresh=[(0i64,0i64);4];let mut fresh_count=0usize;let mut removed_count=0usize;
        if update{if slot0<0||slot0>=se as i64{return -1;}let slot=slot0 as usize;if let Some(old_id)=edge_res[slot]{for j in 0..se{if j!=slot{if let Some(eid)=edge_res[j]{if make_wedge(edges[old_id],edges[eid]).is_some(){removed_count+=1;}}}}}edge_res[slot]=Some(ti);for j in 0..se{if j!=slot{if let Some(eid)=edge_res[j]{if let Some(w)=make_wedge(edges[ti],edges[eid]){fresh[fresh_count]=w;fresh_count+=1;}}}}}else if slot0!=0{return -1;}
        total+=fresh_count as i64-removed_count as i64;if total<0{return -1;}for s in 0..sw{let wd=a[rec+2+2*s];let pick=a[rec+3+2*s];if fresh_count>0{if wd<0||wd>=total{return -1;}if wd<(fresh_count as i64){if pick<0||pick>=fresh_count as i64{return -1;}wedge_res[s]=Some(fresh[pick as usize]);closed[s]=false;}else if pick!=0{return -1;}}else if wd!=0||pick!=0{return -1;}}
        let hits=closed[..sw].iter().filter(|&&x|x).count() as i64;staged[at]=total;staged[at+1]=3*hits*1_000_000/sw as i64;staged[at+2]=hits*(t as i64)*(t as i64)*total*1_000_000/(sw*se*(se-1)) as i64;at+=3;
    }
    let bytes=24*m;if output.is_null()||capacity<bytes{return -2;}let dst=std::slice::from_raw_parts_mut(output,bytes);for i in 0..at{put_i64(&mut dst[8*i..],staged[i]);}bytes as i64
}
