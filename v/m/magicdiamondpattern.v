module magicdiamondpattern
const empty_pattern = '       ...       ....        nothing printing :('
@[export: 'magicdiamondpattern']
pub fn magicdiamondpattern(n i64, output &u8, capacity usize) i64 {
 if n>45{return -1}
 if n<=0 {if unsafe{output==nil}||capacity<usize(empty_pattern.len){return -2};for i in 0..empty_pattern.len{unsafe{output[i]=empty_pattern[i]}};return i64(empty_pattern.len)}
 side:=int(n);required:=3*side*side+4*side;if unsafe{output==nil}||capacity<usize(required){return -2};mut p:=0
 for i in 0..side{for _ in 0..side-i-1{unsafe{output[p]=u8(` `)};p++};for _ in 0..i+1{unsafe{output[p]=u8(`*`)};p++;unsafe{output[p]=u8(` `)};p++};unsafe{output[p]=10};p++}
 mut i:=side;for i>0{i--;for _ in 0..i+1{unsafe{output[p]=u8(`*`)};p++;unsafe{output[p]=u8(` `)};p++};unsafe{output[p]=10};p++;for _ in 0..side-i{unsafe{output[p]=u8(` `)};p++}}
 return i64(p)
}
