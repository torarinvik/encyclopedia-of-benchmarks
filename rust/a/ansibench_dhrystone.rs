// Bounded Dhrystone 2.1 core profile; public-domain upstream notice in package LICENSE.
const I1:i32=0; const I2:i32=1; const I3:i32=2; const I4:i32=3; const I5:i32=4;
#[derive(Clone,Copy)] struct Record { ptr:i32, discr:i32, en:i32, val:i32, text:[u8;31] }
impl Default for Record { fn default()->Self { Self{ptr:0,discr:0,en:0,val:0,text:[0;31]} } }
struct State { glob:i32, boolean:i32, ch1:i32, ch2:i32, a1:[i32;50], a2:[[i32;50];50], rec:[Record;2] }
fn copy(dst:&mut [u8;31],src:&[u8]) { for i in 0..31 { dst[i]=if i<src.len(){src[i]}else{0}; if i>=src.len(){break;} } }
fn cmp(a:&[u8;31],b:&[u8;31])->i32 { for i in 0..31 { if a[i]!=b[i]{return if a[i]<b[i]{-1}else{1};} if a[i]==0{return 0;} } 0 }
fn f1(s:&mut State,a:i32,b:i32)->i32 {if a!=b{I1}else{s.ch1=a;I2}}
fn f3(e:i32)->bool {e==I3}
fn p7(a:i32,b:i32,out:&mut i32){*out=b+(a+2);}
fn p6(s:&State,v:i32,out:&mut i32){*out=v;if !f3(v){*out=I4;}match v{I1=>*out=I1,I2=>*out=if s.glob>100{I1}else{I4},I3=>*out=I2,I4=>(),I5=>*out=I3,_=>()}}
fn p3(s:&mut State,reference:usize){if s.rec[0].ptr>=0{let ptr=s.rec[0].ptr;s.rec[reference].ptr=ptr;}let g=s.glob;p7(10,g,&mut s.rec[0].val);}
fn p1(s:&mut State){let next=s.rec[0].ptr as usize;s.rec[next]=s.rec[0];s.rec[0].val=5;s.rec[next].val=s.rec[0].val;s.rec[next].ptr=s.rec[0].ptr;p3(s,next);if s.rec[next].discr==I1{s.rec[next].val=6;let en=s.rec[0].en;let mut updated=en;p6(s,en,&mut updated);s.rec[next].en=updated;s.rec[next].ptr=s.rec[0].ptr;p7(s.rec[next].val,10,&mut s.rec[next].val);}else{s.rec[0]=s.rec[next];}}
fn p2(s:&State,v:&mut i32){let mut loc=*v+10;let mut e;loop{if s.ch1==b'A' as i32{loc-=1;*v=loc-s.glob;e=I1;}else{e=I2;}if e==I1{break;}}}
fn p4(s:&mut State){let local=(s.ch1==b'A' as i32) as i32;s.boolean=local|s.boolean;s.ch2=b'B' as i32;}
fn p5(s:&mut State){s.ch1=b'A' as i32;s.boolean=0;}
fn p8(s:&mut State,a:i32,b:i32){let loc=a+5;s.a1[loc as usize]=b;s.a1[(loc+1) as usize]=s.a1[loc as usize];s.a1[(loc+30) as usize]=loc;for i in loc..=loc+1{s.a2[loc as usize][i as usize]=loc;}s.a2[loc as usize][(loc-1) as usize]+=1;s.a2[(loc+20) as usize][loc as usize]=s.a1[loc as usize];s.glob=5;}
fn f2(s:&mut State,a:&[u8;31],b:&[u8;31])->bool{let mut loc=2;let mut ch=0;while loc<=2{if f1(s,a[loc] as i32,b[loc+1] as i32)==I1{ch=b'A' as i32;loc+=1;}}if ch>=b'W' as i32&&ch<b'Z' as i32{loc=7;}if ch==b'R' as i32{return true;}if cmp(a,b)>0{loc+=7;s.glob=loc;true}else{false}}
#[no_mangle] pub unsafe extern "C" fn ansibench_dhrystone(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length!=1{return -1;}let passes=*input;if !(1..=8).contains(&passes){return -1;}
 let mut s=State{glob:0,boolean:0,ch1:0,ch2:0,a1:[0;50],a2:[[0;50];50],rec:[Record::default();2]};s.rec[0].ptr=1;s.rec[0].discr=I1;s.rec[0].en=I3;s.rec[0].val=40;copy(&mut s.rec[0].text,b"DHRYSTONE PROGRAM, SOME STRING\0");
 let mut str1=[0u8;31];let mut str2=[0u8;31];copy(&mut str1,b"DHRYSTONE PROGRAM, 1'ST STRING\0");s.a2[8][7]=10;
 let(mut a,mut b,mut c,mut en,mut f2false)=(0,0,0,0,0);
 for run in 1..=passes as i32{p5(&mut s);p4(&mut s);a=2;b=3;copy(&mut str2,b"DHRYSTONE PROGRAM, 2'ND STRING\0");en=I2;f2false=(!f2(&mut s,&str1,&str2)) as i32;while a<b{c=5*a-b;p7(a,b,&mut c);a+=1;}p8(&mut s,a,c);p1(&mut s);for ch in b'A' as i32..=s.ch2{if en==f1(&mut s,ch,b'C' as i32){p6(&s,I1,&mut en);copy(&mut str2,b"DHRYSTONE PROGRAM, 3'RD STRING\0");b=run;s.glob=run;}}b=b*a;a=b/c;b=7*(b-c)-a;p2(&s,&mut a);}
 if output.is_null()||capacity<19{return -2;}let vals=[s.glob,s.boolean,s.ch1,s.ch2,s.a1[8],s.a2[8][7],s.rec[0].discr,s.rec[0].en,s.rec[0].val,s.rec[0].ptr,s.rec[1].discr,s.rec[1].en,s.rec[1].val,s.rec[1].ptr,a,b,c,en,f2false];let out=std::slice::from_raw_parts_mut(output,19);for i in 0..19{out[i]=vals[i] as u8;}19
}
