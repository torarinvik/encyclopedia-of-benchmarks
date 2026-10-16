module lfsr
const max_taps=63
const max_clocks=256
fn feedback(state u64,input &i64,count int)u64{mut bit:=u64(0);for i in 0..count{tap:=int(unsafe{input[6+i]});bit^=(state>>tap)&1};return bit}
fn put(out &u8,slot int,value i64){bits:=u64(value);for i in 0..8{unsafe{out[slot*8+i]=u8(bits>>(i*8))}}}
@[export:'lfsr']
pub fn lfsr(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<6{return -1};width64:=unsafe{input[0]};clock64:=unsafe{input[1]};taps64:=unsafe{input[2]};count64:=unsafe{input[3]};frame64:=unsafe{input[5]};if width64<1||width64>63||clock64<0||clock64>=width64||taps64<0||taps64>max_taps||count64<0||count64>max_clocks||frame64<0||frame64>4194303{return -1}
 width:=int(width64);taps:=int(taps64);clocks:=int(count64);if length!=usize(6+taps){return -1};for i in 0..taps{v:=unsafe{input[6+i]};if v<0||v>=width64{return -1}}
 key:=u64(unsafe{input[4]});frame:=u64(frame64);mut state:=u64(0);mask:=(u64(1)<<width)-1
 for bit in 0..64{idx:=63-bit;state=((state<<1)|(((key>>idx)&1)^feedback(state,input,taps)))&mask}
 for bit in 0..22{idx:=21-bit;state=((state<<1)|(((frame>>idx)&1)^feedback(state,input,taps)))&mask
 bytes:=(clocks+2)*8;if isnil(output)||capacity<usize(bytes){return -2};put(output,0,i64(clocks))
 for i in 0..clocks{out:=(state>>u64(width-1))&1;fb:=feedback(state,input,taps);state=((state<<1)|fb)&mask;put(output,1+i,i64(out))}
 put(output,1+clocks,i64(state));return i64(bytes)
}
