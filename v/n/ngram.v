module ngram
@[export: 'ngram']
pub fn ngram(v &i64,n usize,mut out &u8,cap usize)i64{
 unsafe{if v==nil||n<2||n>258||v[0]<1||v[0]>16||v[1]<0||v[1]>256||n!=usize(v[1])+2{return -1}
 width:=int(v[0]);text:=int(v[1]);for i in 0..text{if v[i+2]<32||v[i+2]>126{return -1}}
 mut grams:=0;if text>=width{grams=text-width+1};mut bytes:=0;if grams>0{bytes=grams*width+grams-1};if usize(bytes)>cap||(bytes>0&&out==nil){return -2}
 mut w:=0;for i in 0..grams{if i>0{out[w]=10;w++};for j in 0..width{out[w]=u8(v[i+j+2]);w++}};return i64(w)}
}
