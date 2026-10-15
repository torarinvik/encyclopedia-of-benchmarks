const MAX_INPUT:usize=1024;const MAX_ENTRIES:usize=1025;
fn ws(c:u8)->bool{(9..=13).contains(&c)||c==32}
fn lower(c:u8)->u8{if c.is_ascii_uppercase(){c+32}else{c}}
fn forbidden(s:&[u8])->bool{[b"constructor".as_slice(),b"tostring",b"tolocalestring",b"valueof",b"hasownproperty",b"isprototypeof",b"propertyisenumerable"].iter().any(|name|s.len()==name.len()&&s.iter().zip(name.iter()).all(|(a,b)|lower(*a)==*b))}
fn put32(out:&mut[u8],pos:&mut usize,x:u32){out[*pos..*pos+4].copy_from_slice(&x.to_le_bytes());*pos+=4;}
#[no_mangle]
pub unsafe extern "C" fn check_word_occurrence(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2{return -1}let packed=std::slice::from_raw_parts(input,length);if !(0..=1).contains(&packed[0])||packed[1]<0||packed[1]>MAX_INPUT as i64||length!=packed[1] as usize+2{return -1}
 let n=packed[1] as usize;let mut text=[0u8;MAX_INPUT];for i in 0..n{let x=packed[i+2];if !(0..=127).contains(&x){return -1}let c=x as u8;if !(c.is_ascii_alphabetic()||ws(c)){return -1}text[i]=if packed[0]==1{lower(c)}else{c}}
 let mut starts=[0usize;MAX_ENTRIES];let mut lens=[0usize;MAX_ENTRIES];let mut counts=[0u32;MAX_ENTRIES];let(mut entries,mut i,mut start)=(0usize,0usize,0usize);
 loop{if i==n||ws(text[i]){let len=i-start;if forbidden(&text[start..i]){return -1}let mut j=0;while j<entries{if lens[j]==len&&text[starts[j]..starts[j]+len]==text[start..i]{break}j+=1}if j==entries{starts[j]=start;lens[j]=len;entries+=1}counts[j]+=1;if i==n{break}while i<n&&ws(text[i]){i+=1}start=i}else{i+=1}}
 let need=4+(0..entries).map(|j|8+lens[j]).sum::<usize>();if capacity<need||output.is_null(){return -2}let out=std::slice::from_raw_parts_mut(output,need);let mut pos=0;put32(out,&mut pos,entries as u32);for j in 0..entries{put32(out,&mut pos,lens[j] as u32);out[pos..pos+lens[j]].copy_from_slice(&text[starts[j]..starts[j]+lens[j]]);pos+=lens[j];put32(out,&mut pos,counts[j]);}need as i64
}
