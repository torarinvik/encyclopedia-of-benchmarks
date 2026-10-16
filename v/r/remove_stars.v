module remove_stars
@[export: 'remove_stars']
pub fn remove_stars(v &i64,n usize,mut out &u8,cap usize)i64{
 unsafe{if v==nil||n<1||n>4097||v[0]<0||v[0]>4096||n!=usize(v[0]+1){return -1}
 mut result:=0
 for i in 0..int(v[0]){if v[i+1]<0||v[i+1]>127{return -1};if v[i+1]==42{if result>0{result--}}else{result++}}
 if usize(result)>cap||(result>0&&out==nil){return -2};mut w:=0
 for i in 0..int(v[0]){if v[i+1]==42{if w>0{w--}}else{out[w]=u8(v[i+1]);w++}}
 return i64(w)}
}
