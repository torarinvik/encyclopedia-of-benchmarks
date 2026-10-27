const MAX_N: usize = 8;
const MAX_M: usize = 16;
const MAX_WORLDS: usize = 8;

fn infected_count(n: usize, world: usize, source_mask: u16, protect_mask: u16,
                  edges: &[(usize,usize,u16)]) -> i64 {
    let mut status=[0u8;MAX_N];let mut rumor_front=[false;MAX_N];let mut protect_front=[false;MAX_N];
    for v in 0..n {if source_mask&(1<<v)!=0{status[v]=1;rumor_front[v]=true;}if protect_mask&(1<<v)!=0{status[v]=2;protect_front[v]=true;}}
    for _ in 0..n {
        let mut rumor_proposal=[false;MAX_N];let mut protect_proposal=[false;MAX_N];
        for &(u,v,mask) in edges {if status[v]!=0{continue;}if protect_front[u]{protect_proposal[v]=true;}if rumor_front[u]&&mask&(1<<world)!=0{rumor_proposal[v]=true;}}
        let mut next_rumor=[false;MAX_N];let mut next_protect=[false;MAX_N];let mut changed=false;
        for v in 0..n {if status[v]==0{if protect_proposal[v]{status[v]=2;next_protect[v]=true;changed=true;}else if rumor_proposal[v]{status[v]=1;next_rumor[v]=true;changed=true;}}}
        rumor_front=next_rumor;protect_front=next_protect;if !changed{break;}
    }
    status[..n].iter().filter(|&&state|state==1).count() as i64
}
fn put_i64(out:&mut [u8],word:usize,value:i64){out[word*8..word*8+8].copy_from_slice(&value.to_le_bytes());}

#[no_mangle]
pub unsafe extern "C" fn rumor_blocking_greedy_live_edge(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||!(5..=61).contains(&length){return -1;}
    let values=std::slice::from_raw_parts(input,length);let(n0,m0,r0,k0,w0)=(values[0],values[1],values[2],values[3],values[4]);
    if !(2..=8).contains(&n0)||!(0..=16).contains(&m0)||r0<1||r0>=n0||!(1..=3).contains(&k0)||!(1..=8).contains(&w0)||k0>n0-r0||length!=5+r0 as usize+3*m0 as usize{return -1;}
    let(n,m,r,k,worlds)=(n0 as usize,m0 as usize,r0 as usize,k0 as usize,w0 as usize);let mut sources=0u16;
    for &v0 in &values[5..5+r]{if v0<0||v0>=n as i64||sources&(1<<v0)!=0{return -1;}sources|=1<<v0;}
    let mut edges=[(0usize,0usize,0u16);MAX_M];let allowed=(1u16<<worlds)-1;let at=5+r;
    for e in 0..m{let(u0,v0,mask0)=(values[at+3*e],values[at+3*e+1],values[at+3*e+2]);if u0<0||u0>=n as i64||v0<0||v0>=n as i64||u0==v0||mask0<0||mask0>allowed as i64{return -1;}let(u,v)=(u0 as usize,v0 as usize);if edges[..e].iter().any(|&(a,b,_)|a==u&&b==v){return -1;}edges[e]=(u,v,mask0 as u16);}
    let graph=&edges[..m];
    let mut baseline=[0i64;MAX_WORLDS];for w in 0..worlds{baseline[w]=infected_count(n,w,sources,0,graph);}
    let mut selected=0u16;let mut chosen=[0i64;MAX_N];let mut scores=[0i64;MAX_N];
    for round in 0..k{let mut current=[0i64;MAX_WORLDS];for w in 0..worlds{current[w]=baseline[w]-infected_count(n,w,sources,selected,graph);}let mut best:Option<(usize,i64)>=None;
      for candidate in 0..n{let bit=1u16<<candidate;if sources&bit!=0||selected&bit!=0{continue;}let mut score=0;for w in 0..worlds{score+=baseline[w]-infected_count(n,w,sources,selected|bit,graph)-current[w];}if best.map_or(true,|(_,old)|score>old){best=Some((candidate,score));}}
      let Some((node,score))=best else{return -1;};selected|=1u16<<node;chosen[round]=node as i64;scores[round]=score;
    }
    let bytes=(1+2*k)*8;if output.is_null()||capacity<bytes{return -2;}let out=std::slice::from_raw_parts_mut(output,bytes);put_i64(out,0,k as i64);for i in 0..k{put_i64(out,1+2*i,chosen[i]);put_i64(out,2+2*i,scores[i]);}bytes as i64
}
