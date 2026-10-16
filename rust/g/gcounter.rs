fn hash_value(mut h:u64,value:i64)->u64{let x=value as u64;for shift in (0..64).step_by(8){h=(h^((x>>shift)&255)).wrapping_mul(0x100000001b3);}h}
#[no_mangle]
pub extern "C" fn gcounter(a:*const i64,n:usize)->i64{
 if a.is_null()||n<2||n>386{return -1;}let x=unsafe{std::slice::from_raw_parts(a,n)};
 if !(1..=8).contains(&x[0])||x[1]<0||x[1]>128||n!=2+3*x[1] as usize{return -1;}
 let nodes=x[0] as usize;let mut s=[[0i64;8];8];let mut h=0xcbf29ce484222325u64;
 for i in 0..x[1] as usize{let op=x[2+3*i];let aa=x[3+3*i];let bb=x[4+3*i];if aa<0||aa>=nodes as i64{return -1;}let a=aa as usize;
 if op==0{if bb!=0||s[a][a]>=1_000_000{return -1;}s[a][a]+=1;}
 else if op==1{if bb!=0{return -1;}let sum:i64=(0..nodes).map(|j|s[a][j]).sum();h=hash_value(h,sum);}
 else if op==2{if bb<0||bb>=nodes as i64{return -1;}let b=bb as usize;h=hash_value(h,(0..nodes).all(|j|s[a][j]<=s[b][j]) as i64);}
 else if op==3{if bb<0||bb>=nodes as i64{return -1;}let b=bb as usize;for j in 0..nodes{s[a][j]=s[a][j].max(s[b][j]);}}
 else{return -1;}}
 for row in s.iter().take(nodes){for value in row.iter().take(nodes){h=hash_value(h,*value);}}h as i64
}
