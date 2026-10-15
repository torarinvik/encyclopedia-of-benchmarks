/// Return BFS seen/visited order and ordered parent and hop-distance maps.
fn put_i64(out:&mut [u8],word:usize,value:i64){out[word*8..word*8+8].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn bfs_result_tree(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3{return -1}let x=std::slice::from_raw_parts(input,length);let nv=x[0];let mv=x[1];let sv=x[2];if !(1..=32).contains(&nv)||!(0..=126).contains(&mv)||sv<0||sv>=nv||length!=3+2*mv as usize{return -1}
 let n=nv as usize;let m=mv as usize;let start=sv as usize;let mut adj:[Vec<usize>;32]=std::array::from_fn(|_|Vec::new());for e in 0..m{let a=x[3+2*e];let b=x[4+2*e];if a<0||a>=nv||b<0||b>=nv{return -1}adj[a as usize].push(b as usize);}
 let mut seen=[false;32];let mut parent=[-1i64;32];let mut distance=[-1i64;32];let mut queue=[0usize;32];let mut order=[0usize;32];let(mut head,mut tail,mut count)=(0usize,0usize,0usize);seen[start]=true;distance[start]=0;queue[tail]=start;tail+=1;
 while head<tail{let v=queue[head];head+=1;order[count]=v;count+=1;for &w in &adj[v]{if !seen[w]{seen[w]=true;parent[w]=v as i64;distance[w]=distance[v]+1;queue[tail]=w;tail+=1;}}}
 let words=4+6*count;if output.is_null()||capacity<words*8{return -2}let out=std::slice::from_raw_parts_mut(output,words*8);let mut k=0;put_i64(out,k,count as i64);k+=1;for &v in &order[..count]{put_i64(out,k,v as i64);k+=1}put_i64(out,k,count as i64);k+=1;for &v in &order[..count]{put_i64(out,k,v as i64);k+=1}put_i64(out,k,count as i64);k+=1;for &v in &order[..count]{put_i64(out,k,v as i64);k+=1;put_i64(out,k,parent[v]);k+=1}put_i64(out,k,count as i64);k+=1;for &v in &order[..count]{put_i64(out,k,v as i64);k+=1;put_i64(out,k,distance[v]);k+=1}let _=n;(words*8) as i64
}
