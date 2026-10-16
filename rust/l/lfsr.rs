const MAX_TAPS:usize=63;const MAX_CLOCKS:usize=256;
fn feedback(state:u64,taps:&[i64])->u64{taps.iter().fold(0,|bit,&tap|bit^((state>>(tap as u32))&1))}
unsafe fn put(out:*mut u8,slot:usize,value:i64){let b=value as u64;for i in 0..8{*out.add(slot*8+i)=(b>>(i*8))as u8;}}
#[no_mangle]
pub unsafe extern "C" fn lfsr(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<6{return -1;}let a=std::slice::from_raw_parts(input,length);if a[0]<1||a[0]>63||a[1]<0||a[1]>=a[0]||a[2]<0||a[2]>MAX_TAPS as i64||a[3]<0||a[3]>MAX_CLOCKS as i64||a[5]<0||a[5]>4194303{return -1;}let width=a[0] as usize;let tap_count=a[2] as usize;let clocks=a[3] as usize;if length!=6+tap_count{return -1;}let taps=&a[6..];if taps.iter().any(|&t|t<0||t>=width as i64){return -1;}
 let mask=(1u64<<width)-1;let key=a[4] as u64;let frame=a[5] as u64;let mut state=0u64;for bit in (0..64).rev(){state=((state<<1)|(((key>>bit)&1)^feedback(state,taps)))&mask;}for bit in (0..22).rev(){state=((state<<1)|(((frame>>bit)&1)^feedback(state,taps)))&mask;}
 let bytes=(clocks+2)*8;if output.is_null()||capacity<bytes{return -2;}put(output,0,clocks as i64);for i in 0..clocks{let out=(state>>(width-1))&1;let fb=feedback(state,taps);state=((state<<1)|fb)&mask;put(output,1+i,out as i64);}put(output,1+clocks,state as i64);bytes as i64
}
