const MAX_N:usize=16;const MAX_M:usize=64;const MAX_Q:usize=32;const MAX_V:usize=17;const MAX_INPUT:usize=276;const MAX_OUTPUT:usize=256;const MAX_W:i64=1_000_000;
unsafe fn store_le(out:*mut u8,at:usize,x:i64){let bits=x as u64;for b in 0..8{*out.add(at+b)=((bits>>(8*b))&255)as u8;}}
fn stoer(n:usize,spokes:&[i64],eu:&[usize],ev:&[usize],ew:&[i64])->i64{
 let vc=n+1;let mut w=[[0i64;MAX_V];MAX_V];for e in 0..eu.len(){w[eu[e]][ev[e]]+=ew[e];w[ev[e]][eu[e]]+=ew[e];}for u in 0..n{w[u][n]+=spokes[u];w[n][u]+=spokes[u];}
 let mut active=[0usize;MAX_V];for i in 0..vc{active[i]=i;}let mut count=vc;let mut best=i64::MAX;
 while count>1{let mut used=[false;MAX_V];let mut conn=[0i64;MAX_V];let mut previous=usize::MAX;
  for step in 0..count{let mut selected=usize::MAX;for z in 0..count{let u=active[z];if !used[u]&&(selected==usize::MAX||conn[u]>conn[selected]||(conn[u]==conn[selected]&&u<selected)){selected=u;}}
   if step+1==count{best=best.min(conn[selected]);for z in 0..count{let u=active[z];if u!=selected&&u!=previous{w[previous][u]+=w[selected][u];w[u][previous]=w[previous][u];}}let pos=active[..count].iter().position(|&u|u==selected).unwrap();for z in pos+1..count{active[z-1]=active[z];}count-=1;break;}
   used[selected]=true;previous=selected;for z in 0..count{let u=active[z];if !used[u]{conn[u]+=w[selected][u];}}
  }
 }best
}
#[no_mangle]
pub unsafe extern "C" fn global_minimum_cut_of_dynamic_star_augmented_graph(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3||length>MAX_INPUT{return -1;}let v=std::slice::from_raw_parts(input,length);let n0=v[0];let m0=v[1];let q0=v[2];if n0<1||n0>MAX_N as i64||m0<0||m0>MAX_M as i64||m0>n0*(n0-1)/2||q0<1||q0>MAX_Q as i64{return -1;}
 let n=n0 as usize;let m=m0 as usize;let q=q0 as usize;if length!=3+n+3*m+2*q{return -1;}let mut pos=3;let mut spokes=[0i64;MAX_N];for i in 0..n{spokes[i]=v[pos];pos+=1;if spokes[i]<0||spokes[i]>MAX_W{return -1;}}
 let mut eu=[0usize;MAX_M];let mut ev=[0usize;MAX_M];let mut ew=[0i64;MAX_M];let mut seen=[[false;MAX_N];MAX_N];for e in 0..m{let u=v[pos];let x=v[pos+1];let weight=v[pos+2];pos+=3;if u<0||u>=n0||x<0||x>=n0||u==x||weight<0||weight>MAX_W{return -1;}let a=u.min(x)as usize;let b=u.max(x)as usize;if seen[a][b]{return -1;}seen[a][b]=true;eu[e]=u as usize;ev[e]=x as usize;ew[e]=weight;}
 let mut ux=[0usize;MAX_Q];let mut uy=[0i64;MAX_Q];for i in 0..q{let x=v[pos];let y=v[pos+1];pos+=2;if x<0||x>=n0||y<0||y>MAX_W{return -1;}ux[i]=x as usize;uy[i]=y;}
 let bytes=8*q;if bytes>MAX_OUTPUT{return -1;}if output.is_null()||capacity<bytes{return -2;}let mut answers=[0i64;MAX_Q];for i in 0..q{spokes[ux[i]]=uy[i];answers[i]=stoer(n,&spokes[..n],&eu[..m],&ev[..m],&ew[..m]);}for i in 0..q{store_le(output,8*i,answers[i]);}bytes as i64
}
