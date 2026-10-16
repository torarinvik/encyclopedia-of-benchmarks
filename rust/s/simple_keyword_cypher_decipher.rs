const MAX_INPUT: usize = 322;
#[no_mangle]
pub unsafe extern "C" fn simple_keyword_cypher_decipher(v: *const i64, n: usize, out: *mut u8, cap: usize) -> i64 {
 if v.is_null() || n < 2 || n > 323 { return -1; }
 let a=std::slice::from_raw_parts(v,n); let kl=a[0];let ml=a[1];
 if !(0..=64).contains(&kl)||!(0..=256).contains(&ml)||n!=2+kl as usize+ml as usize{return -1;}
 let mut key=[0u8;26];let mut count=0usize;
 for &x in &a[2..2+kl as usize]{if !((65..=90).contains(&x)||(97..=122).contains(&x)){return -1;}let c=if x>=97{(x-32) as u8}else{x as u8};if !key[..count].contains(&c){key[count]=c;count+=1;}}
 let mut map=[0u8;26];let mut k=0;for &c in &key[..count]{map[k]=c;k+=1;}for c in b'A'..=b'Z'{if !key[..count].contains(&c){map[k]=c;k+=1;}}
 let mut result=[0u8;256];for (i,&x) in a[2+kl as usize..].iter().enumerate(){if !(0..=127).contains(&x){return -1;}let c=if (97..=122).contains(&x){(x-32) as u8}else{x as u8};if (65..=90).contains(&c){let j=map.iter().position(|&m|m==c).unwrap();result[i]=b'A'+j as u8;}else{result[i]=c;}}
 if out.is_null()||cap<ml as usize{return -2;}std::ptr::copy_nonoverlapping(result.as_ptr(),out,ml as usize);ml
}
