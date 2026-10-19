package ansibench_dhrystone
import "core:c"

I1 :: 0; I2 :: 1; I3 :: 2; I4 :: 3; I5 :: 4
Record :: struct { ptr: int, discr: int, enum_comp: int, int_comp: int, text: [31]u8 }
State :: struct { int_glob: int, bool_glob: int, ch1: int, ch2: int, arr1: [50]int, arr2: [50][50]int, rec: [2]Record }
copy_text :: proc(dst: ^[31]u8, src: string) { for i in 0..<31 { if i<len(src) { dst[i]=src[i] } else { dst[i]=0; break } } }
cmp_text :: proc(a,b: [31]u8)->int { for i in 0..<31 { if a[i]!=b[i] { return if a[i]<b[i] {-1} else {1} };if a[i]==0 {return 0} };return 0 }
func1 :: proc(s:^State,a,b:int)->int {if a!=b{return I1};s.ch1=a;return I2}
func3 :: proc(e:int)->bool{return e==I3}
proc7 :: proc(a,b:int,out:^int){out^=b+(a+2)}
proc6 :: proc(s:^State,v:int,out:^int){out^=v;if !func3(v){out^=I4};switch v{case I1:out^=I1;case I2:out^=if s.int_glob>100{I1}else{I4};case I3:out^=I2;case I4:case I5:out^=I3;case:}}
proc3 :: proc(s:^State,ref:^int){if s.rec[0].ptr>=0{ref^=s.rec[0].ptr};proc7(10,s.int_glob,&s.rec[0].int_comp)}
proc1 :: proc(s:^State){next:=s.rec[0].ptr;s.rec[next]=s.rec[0];s.rec[0].int_comp=5;s.rec[next].int_comp=s.rec[0].int_comp;s.rec[next].ptr=s.rec[0].ptr;proc3(s,&s.rec[next].ptr);if s.rec[next].discr==I1{s.rec[next].int_comp=6;v:=s.rec[0].enum_comp;proc6(s,v,&s.rec[next].enum_comp);s.rec[next].ptr=s.rec[0].ptr;proc7(s.rec[next].int_comp,10,&s.rec[next].int_comp)}else{s.rec[0]=s.rec[next]}}
proc2 :: proc(s:^State,v:^int){loc:=v^+10;en:=0;for{if s.ch1=='A'{loc-=1;v^=loc-s.int_glob;en=I1}else{en=I2};if en==I1{break}}}
proc4 :: proc(s:^State){local:=0;if s.ch1=='A'{local=1};s.bool_glob=local|s.bool_glob;s.ch2='B'}
proc5 :: proc(s:^State){s.ch1='A';s.bool_glob=0}
proc8 :: proc(s:^State,a,b:int){loc:=a+5;s.arr1[loc]=b;s.arr1[loc+1]=s.arr1[loc];s.arr1[loc+30]=loc;for i:=loc;i<=loc+1;i+=1{s.arr2[loc][i]=loc};s.arr2[loc][loc-1]+=1;s.arr2[loc+20][loc]=s.arr1[loc];s.int_glob=5}
func2 :: proc(s:^State,a,b:^ [31]u8)->bool{loc:=2;ch:=0;for loc<=2{if func1(s,int(a[loc]),int(b[loc+1]))==I1{ch='A';loc+=1}};if ch>='W'&&ch<'Z'{loc=7};if ch=='R'{return true};if cmp_text(a^,b^)>0{loc+=7;s.int_glob=loc;return true};return false}
@(export)
ansibench_dhrystone :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length!=1||input[0]<1||input[0]>8{return -1}
 s:State={};s.rec[0].ptr=1;s.rec[0].discr=I1;s.rec[0].enum_comp=I3;s.rec[0].int_comp=40;copy_text(&s.rec[0].text,"DHRYSTONE PROGRAM, SOME STRING")
 str1,str2:[31]u8={};copy_text(&str1,"DHRYSTONE PROGRAM, 1'ST STRING");s.arr2[8][7]=10
 a,b,cc,en,f2false:=0,0,0,0,0
 for run:=1;run<=int(input[0]);run+=1{proc5(&s);proc4(&s);a,b=2,3;copy_text(&str2,"DHRYSTONE PROGRAM, 2'ND STRING");en=I2;if func2(&s,&str1,&str2){f2false=0}else{f2false=1};for a<b{cc=5*a-b;proc7(a,b,&cc);a+=1};proc8(&s,a,cc);proc1(&s);for ch:=int('A');ch<=s.ch2;ch+=1{if en==func1(&s,ch,int('C')){proc6(&s,I1,&en);copy_text(&str2,"DHRYSTONE PROGRAM, 3'RD STRING");b=run;s.int_glob=run}};b=b*a;a=b/cc;b=7*(b-cc)-a;proc2(&s,&a)}
 if output==nil||capacity<19{return -2}
 values:=[19]int{s.int_glob,s.bool_glob,s.ch1,s.ch2,s.arr1[8],s.arr2[8][7],s.rec[0].discr,s.rec[0].enum_comp,s.rec[0].int_comp,s.rec[0].ptr,s.rec[1].discr,s.rec[1].enum_comp,s.rec[1].int_comp,s.rec[1].ptr,a,b,cc,en,f2false}
 for i:=0;i<19;i+=1{output[i]=u8(values[i])};return 19
}
