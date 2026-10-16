module first_fundamental_form
fn feed(h u64,x i64)u64{mut hash:=h;u:=u64(x);for b in 0..8{hash=(hash^((u>>(8*b))&255))*u64(0x100000001b3)};return hash}
fn product(a [3]i64,b [3]i64,mut o [6]i64){o[0]+=a[0]*b[0];o[1]+=a[0]*b[1]+a[1]*b[0];o[2]+=a[0]*b[2]+a[2]*b[0];o[3]+=a[1]*b[1];o[4]+=a[1]*b[2]+a[2]*b[1];o[5]+=a[2]*b[2]}
@[export: 'first_fundamental_form']
pub fn first_fundamental_form(v &i64,n usize)i64{
 unsafe {
 if isnil(v)||n!=18{return -1};for i in 0..18{if v[i]< -100||v[i]>100{return -1}}
 mut ru:=[3][3]i64{};mut rv:=[3][3]i64{};mut e:=[6]i64{};mut f:=[6]i64{};mut g:=[6]i64{}
 for k in 0..3{i:=6*k;ru[k]=[v[i+1],2*v[i+3],v[i+4]]!;rv[k]=[v[i+2],v[i+4],2*v[i+5]]!}
 for k in 0..3{product(ru[k],ru[k],mut e);product(ru[k],rv[k],mut f);product(rv[k],rv[k],mut g)}
 mut h:=u64(0xcbf29ce484222325);for x in e{h=feed(h,x)};for x in f{h=feed(h,x)};for x in g{h=feed(h,x)};return i64(h)
 }
}
