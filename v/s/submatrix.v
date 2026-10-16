module submatrix
fn feed(mut h u64,x i64)u64{u:=u64(x);for b in 0..8{h=(h^((u>>(8*b))&255))*u64(0x100000001b3)};return h}
@[export: 'submatrix']
pub fn submatrix(v &i64,n usize)i64{
 if isnil(v)||n<6||n>70{return -1};rows:=v[0];cols:=v[1];rs:=v[2];cs:=v[3];nr:=v[4];nc:=v[5];if rows<1||rows>8||cols<1||cols>8||rows*cols>64||n!=usize(6+rows*cols){return -1};if rs<0||rs>rows||cs<0||cs>cols||nr<0||nr>rows||nc<0||nc>cols||rs+nr>rows||cs+nc>cols{return -1};for i in 6..n{if v[i]< -2147483648||v[i]>2147483647{return -1}}
 mut h:=feed(u64(0xcbf29ce484222325),nr);h=feed(h,nc);for r in 0..int(nr){for c in 0..int(nc){h=feed(h,v[6+(int(rs)+r)*int(cols)+int(cs)+c])}};return i64(h)
}
