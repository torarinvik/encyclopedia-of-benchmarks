#[no_mangle]
pub unsafe extern "C" fn ngram(v: *const i64,n: usize,out: *mut u8,cap: usize)->i64{
 if v.is_null()||n<2||n>258{return -1;}let a=std::slice::from_raw_parts(v,n);if a[0]<1||a[0]>16||a[1]<0||a[1]>256||n!=a[1] as usize+2{return -1;}
 let width=a[0] as usize;let text=a[1] as usize;let chars=&a[2..];if chars.iter().any(|&c|!(32..=126).contains(&c)){return -1;}
 let grams=if text>=width{text-width+1}else{0};let bytes=if grams>0{grams*width+grams-1}else{0};if bytes>cap||(bytes>0&&out.is_null()){return -2;}
 let mut w=0;for i in 0..grams{if i>0{*out.add(w)=10;w+=1;}for j in 0..width{*out.add(w)=chars[i+j] as u8;w+=1;}}w as i64
}
