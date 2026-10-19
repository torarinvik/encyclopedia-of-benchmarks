const i1 = 0
const i2 = 1
const i3 = 2
const i4 = 3
const i5 = 4

struct DRecord { mut: ptr int; discr int; enum_comp int; int_comp int; text [31]u8 }
struct DState { mut: int_glob int; bool_glob int; ch1 int; ch2 int; arr1 [50]int; arr2 [50][50]int; rec [2]DRecord }
fn copy_text(mut dst [31]u8, src string) { for i in 0..31 { if i<src.len { dst[i]=src[i] } else { dst[i]=0; break } } }
fn cmp_text(a [31]u8,b [31]u8) int { for i in 0..31 { if a[i]!=b[i] { return if a[i]<b[i] {-1} else {1} };if a[i]==0{return 0} };return 0 }
fn func1(mut s DState,a int,b int) int { if a!=b{return i1};s.ch1=a;return i2 }
fn func3(e int) bool {return e==i3}
fn proc7(a int,b int,mut out int) {out=b+(a+2)}
fn proc6(s DState,v int,mut out int) {out=v;if !func3(v){out=i4};match v{i1{out=i1} i2{out=if s.int_glob>100{i1}else{i4}} i3{out=i2} i4{} i5{out=i3} else{}}}
fn proc3(mut s DState,mut reference int) {if s.rec[0].ptr>=0{reference=s.rec[0].ptr};proc7(10,s.int_glob,mut s.rec[0].int_comp)}
fn proc1(mut s DState) {next:=s.rec[0].ptr;s.rec[next]=s.rec[0];s.rec[0].int_comp=5;s.rec[next].int_comp=s.rec[0].int_comp;s.rec[next].ptr=s.rec[0].ptr;proc3(mut s,mut s.rec[next].ptr);if s.rec[next].discr==i1{s.rec[next].int_comp=6;proc6(s,s.rec[0].enum_comp,mut s.rec[next].enum_comp);s.rec[next].ptr=s.rec[0].ptr;proc7(s.rec[next].int_comp,10,mut s.rec[next].int_comp)}else{s.rec[0]=s.rec[next]}}
fn proc2(s DState,mut value int) {mut loc:=value+10;mut en:=0;for{if s.ch1==int(`A`){loc--;value=loc-s.int_glob;en=i1}else{en=i2};if en==i1{break}}}
fn proc4(mut s DState) {local:=if s.ch1==int(`A`){1}else{0};s.bool_glob=local|s.bool_glob;s.ch2=int(`B`)}
fn proc5(mut s DState) {s.ch1=int(`A`);s.bool_glob=0}
fn proc8(mut s DState,a int,b int) {loc:=a+5;s.arr1[loc]=b;s.arr1[loc+1]=s.arr1[loc];s.arr1[loc+30]=loc;for i in loc..loc+2{s.arr2[loc][i]=loc};s.arr2[loc][loc-1]++;s.arr2[loc+20][loc]=s.arr1[loc];s.int_glob=5}
fn func2(mut s DState,a [31]u8,b [31]u8) bool {mut loc:=2;mut ch:=0;for loc<=2{if func1(mut s,int(a[loc]),int(b[loc+1]))==i1{ch=int(`A`);loc++}};if ch>=int(`W`)&&ch<int(`Z`){loc=7};if ch==int(`R`){return true};if cmp_text(a,b)>0{loc+=7;s.int_glob=loc;return true};return false}

@[export: 'ansibench_dhrystone']
pub fn ansibench_dhrystone(input &i64,length usize,mut output &u8,capacity usize) i64 {
    if unsafe { input == nil } || length!=1 || input[0]<1 || input[0]>8{return -1}
    mut s:=DState{};s.rec[0].ptr=1;s.rec[0].discr=i1;s.rec[0].enum_comp=i3;s.rec[0].int_comp=40;copy_text(mut s.rec[0].text,'DHRYSTONE PROGRAM, SOME STRING')
    mut str1:=[31]u8{};mut str2:=[31]u8{};copy_text(mut str1,"DHRYSTONE PROGRAM, 1'ST STRING");s.arr2[8][7]=10
    mut a:=0;mut b:=0;mut cc:=0;mut en:=0;mut f2false:=0
    for run in 1..=int(input[0]) {proc5(mut s);proc4(mut s);a=2;b=3;copy_text(mut str2,"DHRYSTONE PROGRAM, 2'ND STRING");en=i2;f2false=if func2(mut s,str1,str2){0}else{1};for a<b{cc=5*a-b;proc7(a,b,mut cc);a++};proc8(mut s,a,cc);proc1(mut s);for ch in int(`A`)..=s.ch2{if en==func1(mut s,ch,int(`C`)){proc6(s,i1,mut en);copy_text(mut str2,"DHRYSTONE PROGRAM, 3'RD STRING");b=run;s.int_glob=run}};b=b*a;a=b/cc;b=7*(b-cc)-a;proc2(s,mut a)}
    if unsafe { output == nil } || capacity<19{return -2}
    values:=[19]int{s.int_glob,s.bool_glob,s.ch1,s.ch2,s.arr1[8],s.arr2[8][7],s.rec[0].discr,s.rec[0].enum_comp,s.rec[0].int_comp,s.rec[0].ptr,s.rec[1].discr,s.rec[1].enum_comp,s.rec[1].int_comp,s.rec[1].ptr,a,b,cc,en,f2false}
    for i in 0..19{output[i]=u8(values[i])};return 19
}
