module entropy
import math
const max_text = 512
const alphabet_size = 128
fn round_even(value f64) int { lower:=math.floor(value);fraction:=value-lower;if fraction<0.5{return int(lower)};if fraction>0.5{return int(lower+1)};n:=int(lower);if n%2==0{return n};return n+1 }
fn emit_line(mut out [32]u8,pos_input int,value_input int) int {mut pos:=pos_input;mut value:=value_input;if value<0{out[pos]=u8('-');pos++;value=-value};if value>=10{out[pos]=u8(48+value/10);pos++};out[pos]=u8(48+value%10);pos++;out[pos]=u8('.');pos++;out[pos]=u8('0');pos++;out[pos]=u8(10);pos++;return pos}

// Emit the source's rounded single/bigram entropy values and their difference.
@[export: 'entropy']
pub fn entropy(input &i64,length usize,output &u8,capacity usize) i64 {
 if length<2||length>max_text+1{return -1}
 unsafe {
  n:=input[0];if n<1||n>max_text||length!=usize(n+1){return -1}
  mut singles:=[128]i64{};mut pairs:=[16384]i64{}
  for i in 0..int(n){ch:=input[i+1];if ch<0||ch>=128{return -1};singles[int(ch)]++}
  pairs[32*128+int(input[1])]++
  for i in 0..int(n)-1{pairs[int(input[i+1])*128+int(input[i+2])]++}
  alpha:=[27]int{32,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122};mut s1:=f64(0);mut s2:=f64(0)
  for a in alpha{count:=singles[a];if count>0{p:=f64(count)/f64(n);s1+=p*math.log2(p)}}
  for a in alpha{for b in alpha{count:=pairs[a*128+b];if count>0{p:=f64(count)/f64(n);s2+=p*math.log2(p)}}}
  mut temp:=[32]u8{};mut written:=emit_line(mut temp,0,round_even(-s1));written=emit_line(mut temp,written,round_even(-s2));written=emit_line(mut temp,written,round_even((-s2)-(-s1)));if capacity<usize(written){return -2};for i in 0..written{output[i]=temp[i]};return i64(written)
 }
}
