const MAX_CIPHER: usize = 4096;
const KEY_COUNT: usize = 17_576;
fn allowed(value:i64)->bool{(9..=13).contains(&value)||(32..=126).contains(&value)}
fn word(id:usize)->&'static [u8]{[b"the",b"be",b"to",b"of",b"and",b"in",b"that",b"have"][id]}
fn contains_word(input:&[i64],keys:&[[u8;3];KEY_COUNT],index:usize,w:&[u8])->bool{
 if input.len()<w.len(){return false;} for start in 0..=input.len()-w.len(){let mut matched=true;for j in 0..w.len(){let pos=start+j;let mut ch=(input[pos] as u8)^keys[index][pos%3];if ch>=65&&ch<=90{ch+=32;}if ch!=w[j]{matched=false;break;}}if matched{return true;}}false
}
#[no_mangle]
pub unsafe extern "C" fn problem59(input:*const i64,length:usize)->i64{
 if input.is_null()||length==0||length>MAX_CIPHER{return -1;}let values=std::slice::from_raw_parts(input,length);if values.iter().any(|&v|!(0..=255).contains(&v)){return -1;}
 let mut keys=[[0u8;3];KEY_COUNT];let mut count=0usize;
 for a in 97u8..=122{for b in 97u8..=122{for c in 97u8..=122{let key=[a,b,c];if values.iter().enumerate().all(|(i,&v)|allowed(v^i64::from(key[i%3]))){keys[count]=key;count+=1;}}}}
 for w in 0..8{let mut kept=0usize;for i in 0..count{if contains_word(values,&keys,i,word(w)){keys[kept]=keys[i];kept+=1;}}count=kept;if count==1{break;}}
 if count==0{return -1;}values.iter().enumerate().map(|(i,&v)|v^i64::from(keys[0][i%3])).sum()
}
