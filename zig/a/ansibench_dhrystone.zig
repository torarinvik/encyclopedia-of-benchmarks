// Bounded Dhrystone 2.1 core profile; public-domain source notice in package LICENSE.
const I1: i32=0; const I2: i32=1; const I3: i32=2; const I4: i32=3; const I5: i32=4;
const Record=struct{ptr:i32=0,discr:i32=0,en:i32=0,value:i32=0,text:[31]u8=@splat(0)};
const State=struct{glob:i32=0,boolean:i32=0,ch1:i32=0,ch2:i32=0,a1:[50]i32=@splat(0),a2:[50][50]i32=@splat(@splat(0)),rec:[2]Record=@splat(.{})};
fn copyText(dst:*[31]u8,src:[]const u8) void {@memset(dst,0);@memcpy(dst[0..src.len],src);}
fn cmpText(a:*const [31]u8,b:*const [31]u8)i32{for(0..31)|i|{if(a[i]!=b[i])return if(a[i]<b[i]) -1 else 1;if(a[i]==0)return 0;}return 0;}
fn f1(s:*State,a:i32,b:i32)i32{if(a!=b)return I1;s.ch1=a;return I2;}
fn f3(e:i32)bool{return e==I3;}
fn p7(a:i32,b:i32,out:*i32)void{out.*=b+(a+2);}
fn p6(s:*const State,v:i32,out:*i32)void{out.*=v;if(!f3(v))out.*=I4;switch(v){I1=>out.*=I1,I2=>out.*=if(s.glob>100) I1 else I4,I3=>out.*=I2,I4=>{},I5=>out.*=I3,else=>{}}}
fn p3(s:*State,ref_index:usize)void{if(s.rec[0].ptr>=0)s.rec[ref_index].ptr=s.rec[0].ptr;p7(10,s.glob,&s.rec[0].value);}
fn p1(s:*State)void{const next:usize=@intCast(s.rec[0].ptr);s.rec[next]=s.rec[0];s.rec[0].value=5;s.rec[next].value=s.rec[0].value;s.rec[next].ptr=s.rec[0].ptr;p3(s,next);if(s.rec[next].discr==I1){s.rec[next].value=6;const en=s.rec[0].en;p6(s,en,&s.rec[next].en);s.rec[next].ptr=s.rec[0].ptr;p7(s.rec[next].value,10,&s.rec[next].value);}else{s.rec[0]=s.rec[next];}}
fn p2(s:*const State,v:*i32)void{var loc=v.*+10;var e:i32=0;while(true){if(s.ch1=='A'){loc-=1;v.*=loc-s.glob;e=I1;}else{e=I2;}if(e==I1)break;}}
fn p4(s:*State)void{const local:i32=if(s.ch1=='A') 1 else 0;s.boolean=local|s.boolean;s.ch2='B';}
fn p5(s:*State)void{s.ch1='A';s.boolean=0;}
fn p8(s:*State,a:i32,b:i32)void{const loc:usize=@intCast(a+5);s.a1[loc]=b;s.a1[loc+1]=s.a1[loc];s.a1[loc+30]=@intCast(loc);for(loc..loc+2)|i|s.a2[loc][i]=@intCast(loc);s.a2[loc][loc-1]+=1;s.a2[loc+20][loc]=s.a1[loc];s.glob=5;}
fn f2(s:*State,a:*const [31]u8,b:*const [31]u8)bool{var loc:i32=2;var ch:i32=0;while(loc<=2){if(f1(s,a[@intCast(loc)],b[@intCast(loc+1)])==I1){ch='A';loc+=1;}}if(ch>='W' and ch<'Z')loc=7;if(ch=='R')return true;if(cmpText(a,b)>0){s.glob=loc+7;return true;}return false;}
export fn ansibench_dhrystone(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length!=1 or input[0]<1 or input[0]>8)return -1;
 var s:State=.{};s.rec[0].ptr=1;s.rec[0].discr=I1;s.rec[0].en=I3;s.rec[0].value=40;copyText(&s.rec[0].text,"DHRYSTONE PROGRAM, SOME STRING");
 var str1:[31]u8=@splat(0);var str2:[31]u8=@splat(0);copyText(&str1,"DHRYSTONE PROGRAM, 1'ST STRING");s.a2[8][7]=10;
 var a:i32=0;var b:i32=0;var c:i32=0;var en:i32=0;var f2false:i32=0;
 for(1..@as(usize,@intCast(input[0]))+1)|run0|{const run:i32=@intCast(run0);p5(&s);p4(&s);a=2;b=3;copyText(&str2,"DHRYSTONE PROGRAM, 2'ND STRING");en=I2;f2false=if(f2(&s,&str1,&str2)) 0 else 1;while(a<b){c=5*a-b;p7(a,b,&c);a+=1;}p8(&s,a,c);p1(&s);var ch:i32='A';while(ch<=s.ch2):(ch+=1){if(en==f1(&s,ch,'C')){p6(&s,I1,&en);copyText(&str2,"DHRYSTONE PROGRAM, 3'RD STRING");b=run;s.glob=run;}}b=b*a;a=@divTrunc(b,c);b=7*(b-c)-a;p2(&s,&a);}
 if(output==null or capacity<19)return -2;
 const vals=[_]i32{s.glob,s.boolean,s.ch1,s.ch2,s.a1[8],s.a2[8][7],s.rec[0].discr,s.rec[0].en,s.rec[0].value,s.rec[0].ptr,s.rec[1].discr,s.rec[1].en,s.rec[1].value,s.rec[1].ptr,a,b,c,en,f2false};var staged:[19]u8=@splat(0);for(0..19)|i|staged[i]=@intCast(vals[i]);@memcpy(output[0..19],&staged);return 19;
}
