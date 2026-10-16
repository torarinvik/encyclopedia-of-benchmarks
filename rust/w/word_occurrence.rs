const MAX_INPUT:usize=1024;const MAX_ENTRIES:usize=512;
fn ws(c:u8)->bool{(9..=13).contains(&c)||(28..=32).contains(&c)}
fn put32(out:&mut[u8],pos:&mut usize,value:u32){out[*pos..*pos+4].copy_from_slice(&value.to_le_bytes());*pos+=4;}
#[no_mangle]
pub unsafe extern "C" fn word_occurrence(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<1||length>MAX_INPUT+1{return -1;}let packed=std::slice::from_raw_parts(input,length);if packed[0]<0||packed[0]>MAX_INPUT as i64||length!=packed[0]as usize+1{return -1;}
 let n=packed[0]as usize;let mut text=[0u8;MAX_INPUT];for i in 0..n{let v=packed[i+1];if !(0..=127).contains(&v){return -1;}text[i]=v as u8;}
 let mut starts=[0usize;MAX_ENTRIES];let mut lens=[0usize;MAX_ENTRIES];let mut counts=[0u32;MAX_ENTRIES];let mut entries=0usize;let mut i=0usize;
 while i<n{while i<n&&ws(text[i]){i+=1;}if i==n{break;}let start=i;while i<n&&!ws(text[i]){i+=1;}let len=i-start;let mut j=0;while j<entries{if lens[j]==len&&text[starts[j]..starts[j]+len]==text[start..i]{break;}j+=1;}if j==entries{if entries>=MAX_ENTRIES{return -1;}starts[j]=start;lens[j]=len;entries+=1;}counts[j]+=1;}
 let need=4+(0..entries).map(|j|8+lens[j]).sum::<usize>();if output.is_null()||capacity<need{return -2;}let out=std::slice::from_raw_parts_mut(output,need);let mut pos=0;put32(out,&mut pos,entries as u32);for j in 0..entries{put32(out,&mut pos,lens[j]as u32);out[pos..pos+lens[j]].copy_from_slice(&text[starts[j]..starts[j]+lens[j]]);pos+=lens[j];put32(out,&mut pos,counts[j]);}need as i64
}
