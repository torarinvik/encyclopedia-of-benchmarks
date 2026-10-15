const MAX_V: usize=8; const MAX_E: usize=24; const MAX_P: usize=1000; const MAX_OUT: usize=72008;
fn put_i64(out:&mut [u8;MAX_OUT],at:usize,value:i64){out[at..at+8].copy_from_slice(&value.to_le_bytes());}
unsafe fn dfs(adj:&[[usize;MAX_E];MAX_V],degree:&[usize;MAX_V],visited:&mut [bool;MAX_V],path:&mut [usize;MAX_V],depth:usize,target:usize,count:&mut usize,out:&mut [u8;MAX_OUT],at:&mut usize,overflow:&mut bool){
    if *overflow{return;}let u=path[depth-1];if u==target{if *count>=MAX_P{*overflow=true;return;}put_i64(out,*at,depth as i64);*at+=8;for &x in &path[..depth]{put_i64(out,*at,x as i64);*at+=8;}*count+=1;return;}
    visited[u]=true;for &next in &adj[u][..degree[u]]{if !visited[next]{path[depth]=next;dfs(adj,degree,visited,path,depth+1,target,count,out,at,overflow);if *overflow{break;}}}visited[u]=false;
}
#[no_mangle]
pub unsafe extern "C" fn all_paths_from_source_to_target(v:*const i64,n:usize,output:*mut u8,capacity:usize)->i64{
    if v.is_null()||n<4||n>52{return -1;}let v=std::slice::from_raw_parts(v,n);if !(1..=MAX_V as i64).contains(&v[0])||!(0..=MAX_E as i64).contains(&v[1]){return -1;}
    let nv=v[0] as usize;let ne=v[1] as usize;if v[2]<0||v[2]>=nv as i64||v[3]<0||v[3]>=nv as i64||n!=4+2*ne{return -1;}
    let(mut adj,mut degree)=([[0usize;MAX_E];MAX_V],[0usize;MAX_V]);for e in 0..ne{let(a,b)=(v[4+2*e],v[5+2*e]);if a<0||a>=nv as i64||b<0||b>=nv as i64{return -1;}let u=a as usize;adj[u][degree[u]]=b as usize;degree[u]+=1;}
    let(mut visited,mut path,mut out)=([false;MAX_V],[0usize;MAX_V],[0u8;MAX_OUT]);let(mut count,mut at,mut overflow)=(0usize,8usize,false);path[0]=v[2] as usize;
    dfs(&adj,&degree,&mut visited,&mut path,1,v[3] as usize,&mut count,&mut out,&mut at,&mut overflow);if overflow{return -2;}put_i64(&mut out,0,count as i64);if output.is_null()||capacity<at{return -2;}std::ptr::copy_nonoverlapping(out.as_ptr(),output,at);at as i64
}
