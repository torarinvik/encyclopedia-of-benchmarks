module crust_pole_triangle_filter

const max_facets=16
const max_vertices=12

fn put_i64_le(mut output &u8,word int,value i64){bits:=u64(value);for b in 0..8{unsafe{output[word*8+b]=u8((bits>>(8*b))&255)}}}
fn tri_less(a [3]int,b [3]int)bool{for i in 0..3{if a[i]<b[i]{return true};if a[i]>b[i]{return false}};return false}
fn tri_equal(a [3]int,b [3]int)bool{return a[0]==b[0]&&a[1]==b[1]&&a[2]==b[2]}

@[export:'crust_pole_triangle_filter']
pub fn crust_pole_triangle_filter(input &i64,length usize,mut output &u8,capacity usize)i64{
	if input==nil||length<3||length>51{return -1};ns0:=unsafe{input[0]};np0:=unsafe{input[1]};nf0:=unsafe{input[2]}
	if ns0<3||ns0>8||np0<1||np0>4||ns0+np0>max_vertices||nf0<0||nf0>max_facets||length!=usize(3+3*nf0){return -1}
	ns:=int(ns0);total:=int(ns0+np0);nf:=int(nf0);mut facets:=[max_facets][3]int{};mut count:=0
	for i in 0..nf{mut tri:=[3]int{unsafe{int(input[3+3*i])},unsafe{int(input[4+3*i])},unsafe{int(input[5+3*i])}};if tri[0]<0||tri[0]>=total||tri[1]<0||tri[1]>=total||tri[2]<0||tri[2]>=total||tri[0]==tri[1]||tri[0]==tri[2]||tri[1]==tri[2]{return -1};if tri[0]>=ns||tri[1]>=ns||tri[2]>=ns{continue}
		for a:=1;a<3;a++{x:=tri[a];mut j:=a;for j>0&&tri[j-1]>x{tri[j]=tri[j-1];j--};tri[j]=x};mut duplicate:=false;for j in 0..count{if tri_equal(tri,facets[j]){duplicate=true}};if !duplicate{facets[count]=tri;count++}
	}
	for i:=1;i<count;i++{x:=facets[i];mut j:=i;for j>0&&tri_less(x,facets[j-1]){facets[j]=facets[j-1];j--};facets[j]=x}
	bytes:=(1+3*count)*8;if output==nil||capacity<usize(bytes){return -2};put_i64_le(mut output,0,i64(count));mut at:=1;for i in 0..count{for j in 0..3{put_i64_le(mut output,at,i64(facets[i][j]));at++}};return i64(bytes)
}
