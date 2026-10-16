package word_frequency_functions
import "core:c"
import "core:math"

Max_Term :: 128
Max_Text :: 4096
Max_Packed :: 4227
Max_Count :: i64(1_000_000)
punct :: proc "contextless" (c:u8)->bool{return(c>=33&&c<=47)||(c>=58&&c<=64)||(c>=91&&c<=96)||(c>=123&&c<=126)}
lower_ascii :: proc "contextless" (c:u8)->u8{if c>=65&&c<=90{return c+32};return c}
put32 :: proc "contextless" (out:[^]u8,pos:^usize,x:u32){bits:=x;for i:usize=0;i<4;i+=1{out[pos^]=u8(bits&255);pos^+=1;bits>>=8}}
put64 :: proc "contextless" (out:[^]u8,pos:^usize,x:i64){bits:=u64(x);for i:usize=0;i<8;i+=1{out[pos^]=u8(bits&255);pos^+=1;bits>>=8}}
milli :: proc "contextless" (x:f64)->i64{y:=x*1000.0;lo:=math.floor_f64(y);f:=y-lo;if f<0.5{return i64(lo)};if f>0.5{return i64(lo+1.0)};k:=i64(lo);if k%2==0{return k};return k+1}

@(export)
word_frequency_functions :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
    if input==nil||length<1||length>Max_Packed do return -1
    op:=input[0];kind:i64=0;a:i64=0;b:i64=0;out_len:usize=12
    if op==0||op==1 {
        if length<3||input[1]<0||input[1]>Max_Term do return -1
        tn:=int(input[1]);ti:=2+tn
        if int(length)<ti+1||input[ti]<0||input[ti]>Max_Text do return -1
        dn:=int(input[ti]);di:=ti+1;if int(length)!=di+dn do return -1
        term:[Max_Term]u8;text:[Max_Text]u8;clean:[Max_Text]u8
        for i:=0;i<tn;i+=1{v:=input[2+i];if v<0||v>127 do return -1;term[i]=lower_ascii(u8(v))}
        for i:=0;i<dn;i+=1{v:=input[di+i];if v<0||v>127 do return -1;text[i]=u8(v)}
        cn:=0;for i:=0;i<dn;i+=1{if !punct(text[i])&&(op!=0||text[i]!=10){clean[cn]=text[i];if op==1 do clean[cn]=lower_ascii(text[i]);cn+=1}}
        if op==0 {
            start:=0
            for i:=0;i<=cn;i+=1{if i==cn||clean[i]==32{n:=i-start;same:=n==tn;for j:=0;same&&j<n;j+=1{if lower_ascii(clean[start+j])!=term[j] do same=false};if same do a+=1;start=i+1}}
        }else{
            kind=1;out_len=20;start:=0
            for i:=0;i<=cn;i+=1{if i==cn||clean[i]==10{n:=i-start;found:=tn==0;for j:=0;!found&&j+tn<=n;j+=1{k:=0;for k<tn&&clean[start+j+k]==term[k]{k+=1};if k==tn do found=true};if found do a+=1;b+=1;start=i+1}}
        }
    }else if op==2{
        if length!=4 do return -1
        df,n,smooth:=input[1],input[2],input[3]
        if df<0||df>Max_Count||n<0||n>Max_Count||(smooth!=0&&smooth!=1) do return -1
        if smooth==1&&n==0{kind=4;out_len=4}else if smooth==0&&df==0{kind=3;out_len=4}else if smooth==0&&n==0{kind=4;out_len=4}else{v:=f64(0);if smooth==1{v=1+math.log10_f64(f64(n)/f64(1+df))}else{v=math.log10_f64(f64(n)/f64(df))};kind=2;a=milli(v)}
    }else if op==3{
        if length!=3||input[1]<0||input[1]>Max_Count||input[2]<-Max_Count||input[2]>Max_Count do return -1
        kind=2;a=input[1]*input[2]
    }else{return -1}
    if output==nil||capacity<out_len do return -2
    pos:usize=0;put32(output,&pos,u32(kind));if kind==0||kind==2{put64(output,&pos,a)}else if kind==1{put64(output,&pos,a);put64(output,&pos,b)}
    return i64(pos)
}
