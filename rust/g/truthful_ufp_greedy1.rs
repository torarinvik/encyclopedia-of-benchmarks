const MAX_N:usize=8;const MAX_M:usize=16;const MAX_K:usize=8;const MAX_INPUT:usize=75;const MAX_OUTPUT:usize=648;
fn put(out:&mut[u8],at:usize,x:i64){out[at..at+8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn truthful_ufp_greedy1(values:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if values.is_null()||length<9||length>MAX_INPUT{return -1;}let a=std::slice::from_raw_parts(values,length);
 if !(2..=MAX_N as i64).contains(&a[0])||a[1]<1||a[1]>MAX_M as i64||!(1..=MAX_K as i64).contains(&a[2]){return -1;}
 let nv=a[0]as usize;let m=a[1]as usize;let k=a[2]as usize;if length!=3+3*m+3*k{return -1;}
 let mut eu=[0usize;MAX_M];let mut ev=[0usize;MAX_M];let mut caps=[0usize;MAX_M];let mut prices=[0.0f64;MAX_M];let mut minimum=9usize;let(mut pu,mut pv)=(-1i64,-1i64);
 for e in 0..m{let u=a[3+3*e];let v=a[4+3*e];let b=a[5+3*e];if u<0||v<=u||v>=nv as i64||!(2..=8).contains(&b)||(e>0&&(u<pu||(u==pu&&v<=pv))){return -1;}eu[e]=u as usize;ev[e]=v as usize;caps[e]=b as usize;prices[e]=1.0/caps[e]as f64;minimum=minimum.min(caps[e]);pu=u;pv=v;}
 let mut src=[0usize;MAX_K];let mut dst=[0usize;MAX_K];let mut bid=[0i64;MAX_K];for i in 0..k{let s=a[3+3*m+3*i];let t=a[4+3*m+3*i];let c=a[5+3*m+3*i];if s<0||s>=nv as i64||t<0||t>=nv as i64||s==t||!(1..=100).contains(&c){return -1;}src[i]=s as usize;dst[i]=t as usize;bid[i]=c;}
 let threshold=2.718281828459045f64.powf((minimum-1)as f64)*m as f64;let mut live=[false;MAX_K];for x in live.iter_mut().take(k){*x=true;}let mut selected=[0usize;MAX_K];let mut path_len=[0usize;MAX_K];let mut paths=[0usize;MAX_K*MAX_N];let mut count=0usize;
 while count<k{let mut best=None;let mut best_score=-1.0f64;let mut route_table=[0usize;MAX_K*MAX_N];let mut route_len=[0usize;MAX_K];
  for i in 0..k{if live[i]{let mut dist=[1e300f64;MAX_N];let mut parent=[-1i32;MAX_N];let mut used=[false;MAX_N];dist[src[i]]=0.0;
   for _ in 0..nv{let mut u=None;for v in 0..nv{if !used[v]&&(u.is_none()||dist[v]<dist[u.unwrap()]||(dist[v]==dist[u.unwrap()]&&v<u.unwrap())){u=Some(v);}}let Some(u)=u else{break};if dist[u]>=1e299{break;}used[u]=true;
    for e in 0..m{let v=if eu[e]==u{Some(ev[e])}else if ev[e]==u{Some(eu[e])}else{None};if let Some(v)=v{if !used[v]{let candidate=dist[u]+prices[e];if candidate<dist[v]||(candidate==dist[v]&&(parent[v]<0||u<parent[v]as usize)){dist[v]=candidate;parent[v]=u as i32;}}}}
   }
   if dist[dst[i]]>=1e299{return -1;}let mut reverse=[0usize;MAX_N];let mut len=0usize;let mut v=dst[i];while v!=src[i]&&len<nv{reverse[len]=v;len+=1;if parent[v]<0{return -1;}v=parent[v]as usize;}if v!=src[i]||len>=nv{return -1;}reverse[len]=src[i];len+=1;route_len[i]=len;for q in 0..len{route_table[i*MAX_N+q]=reverse[len-1-q];}
   let score=bid[i]as f64/dist[dst[i]];if best.is_none()||score>best_score{best=Some(i);best_score=score;}
  }}
  let Some(winner)=best else{break};live[winner]=false;selected[count]=winner;path_len[count]=route_len[winner];for q in 0..path_len[count]{paths[count*MAX_N+q]=route_table[winner*MAX_N+q];}count+=1;
  for q in 0..path_len[count-1]-1{let u=paths[(count-1)*MAX_N+q];let v=paths[(count-1)*MAX_N+q+1];for e in 0..m{if(eu[e]==u&&ev[e]==v)||(eu[e]==v&&ev[e]==u){prices[e]*=threshold.powf(1.0/(caps[e]-1)as f64);}}}
  let mut dual=0.0;for e in 0..m{dual+=caps[e]as f64*prices[e];}if dual>=threshold{break;}
 }
 let mut words=1usize;for i in 0..count{words+=2+path_len[i];}let bytes=8*words;if output.is_null()||capacity<bytes{return -2;}let mut staged=[0u8;MAX_OUTPUT];put(&mut staged,0,count as i64);let mut w=1usize;for i in 0..count{put(&mut staged,8*w,selected[i]as i64);w+=1;put(&mut staged,8*w,path_len[i]as i64);w+=1;for q in 0..path_len[i]{put(&mut staged,8*w,paths[i*MAX_N+q]as i64);w+=1;}}std::ptr::copy_nonoverlapping(staged.as_ptr(),output,bytes);bytes as i64
}
