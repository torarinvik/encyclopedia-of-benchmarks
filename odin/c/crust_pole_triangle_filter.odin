package crust_pole_triangle_filter

import "core:c"

MAX_FACETS :: 16
MAX_VERTICES :: 12

put_i64 :: proc "contextless" (output:[^]u8,word:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[word*8+b]=u8((bits>>(8*b))&255)}}
tri_less :: proc "contextless" (a,b:[3]int)->bool{for i:=0;i<3;i+=1{if a[i]<b[i]return true;if a[i]>b[i]return false};return false}
tri_equal :: proc "contextless" (a,b:[3]int)->bool{return a[0]==b[0]&&a[1]==b[1]&&a[2]==b[2]}

@(export)
crust_pole_triangle_filter :: proc "c" (input:[^]i64,input_length:c.size_t,output:[^]u8,output_capacity:c.size_t)->i64{
    if input==nil||input_length<3||input_length>51 do return -1
    ns0,np0,nf0:=input[0],input[1],input[2]
    if ns0<3||ns0>8||np0<1||np0>4||ns0+np0>MAX_VERTICES||nf0<0||nf0>MAX_FACETS||input_length!=c.size_t(3+3*nf0) do return -1
    ns,total,nf:=int(ns0),int(ns0+np0),int(nf0);facets:[MAX_FACETS][3]int;count:=0
    for i:=0;i<nf;i+=1{
        tri:=[3]int{int(input[3+3*i]),int(input[4+3*i]),int(input[5+3*i])}
        if tri[0]<0||tri[0]>=total||tri[1]<0||tri[1]>=total||tri[2]<0||tri[2]>=total||tri[0]==tri[1]||tri[0]==tri[2]||tri[1]==tri[2] do return -1
        if tri[0]>=ns||tri[1]>=ns||tri[2]>=ns do continue
        for a:=1;a<3;a+=1{x:=tri[a];j:=a;for j>0&&tri[j-1]>x{tri[j]=tri[j-1];j-=1};tri[j]=x}
        duplicate:=false;for j:=0;j<count;j+=1{if tri_equal(tri,facets[j]){duplicate=true}}
        if !duplicate{facets[count]=tri;count+=1}
    }
    for i:=1;i<count;i+=1{x:=facets[i];j:=i;for j>0&&tri_less(x,facets[j-1]){facets[j]=facets[j-1];j-=1};facets[j]=x}
    bytes:=c.size_t((1+3*count)*8);if output==nil||output_capacity<bytes do return -2
    put_i64(output,0,i64(count));at:=1;for i:=0;i<count;i+=1{for j:=0;j<3;j+=1{put_i64(output,at,i64(facets[i][j]));at+=1}};return i64(bytes)
}
