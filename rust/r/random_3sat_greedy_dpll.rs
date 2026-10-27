const MAX_VARS:usize=12;const MAX_CLAUSES:usize=32;const MAX_INPUT:usize=98;const MAX_OUTPUT:usize=104;
fn put(out:&mut[u8],at:usize,x:i64){out[at..at+8].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn random_3sat_greedy_dpll(values:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if values.is_null()||length<2||length>MAX_INPUT{return -1;}let a=std::slice::from_raw_parts(values,length);if !(3..=MAX_VARS as i64).contains(&a[0])||a[1]<0||a[1]>MAX_CLAUSES as i64{return -1;}let nv=a[0]as usize;let m=a[1]as usize;if length!=2+3*m{return -1;}
 let mut clauses=[[0i32;3];MAX_CLAUSES];let mut lens=[0usize;MAX_CLAUSES];let mut active=[false;MAX_CLAUSES];
 for i in 0..m{let mut seen=[false;MAX_VARS];for j in 0..3{let x=a[2+3*i+j];if x==0||x<-(nv as i64)||x>nv as i64{return -1;}let v=x.unsigned_abs()as usize-1;if seen[v]{return -1;}seen[v]=true;clauses[i][j]=x as i32;}lens[i]=3;active[i]=true;}
 let mut assigned=[0i32;MAX_VARS];let mut success=false;let mut failed=false;
 for _ in 0..nv{if failed{break;}let mut remaining=0;for i in 0..m{if active[i]{remaining+=1;}}if remaining==0{success=true;break;}
  let mut chosen=0i32;for i in 0..m{if chosen==0&&active[i]&&lens[i]==1{chosen=clauses[i][0];}}
  if chosen==0{let mut counts=[0usize;2*MAX_VARS];for i in 0..m{if active[i]{for j in 0..lens[i]{let lit=clauses[i][j];let v=lit.unsigned_abs()as usize-1;counts[2*v+usize::from(lit<0)]+=1;}}}let mut best=0;for v in 0..nv{for sign in 0..2{let c=counts[2*v+sign];if c>best{best=c;chosen=if sign==0{(v+1)as i32}else{-((v+1)as i32)};}}}}
  if chosen==0{failed=true;break;}let variable=chosen.unsigned_abs()as usize-1;assigned[variable]=if chosen>0{1}else{-1};
  for i in 0..m{if active[i]{let mut satisfied=false;for j in 0..lens[i]{if clauses[i][j]==chosen{satisfied=true;}}if satisfied{active[i]=false;continue;}let mut w=0;for j in 0..lens[i]{if clauses[i][j]!=-chosen{clauses[i][w]=clauses[i][j];w+=1;}}lens[i]=w;if w==0{failed=true;break;}}}
 }
 if !failed{let mut remaining=0;for i in 0..m{if active[i]{remaining+=1;}}success=remaining==0;}if success{for i in 0..nv{if assigned[i]==0{assigned[i]=-1;}}}
 let bytes=8*(nv+1);if output.is_null()||capacity<bytes{return -2;}let mut staged=[0u8;MAX_OUTPUT];put(&mut staged,0,if success{1}else{0});for i in 0..nv{put(&mut staged,8*(i+1),assigned[i]as i64);}std::ptr::copy_nonoverlapping(staged.as_ptr(),output,bytes);bytes as i64
}
