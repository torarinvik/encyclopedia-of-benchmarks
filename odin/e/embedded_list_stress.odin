package embedded_list_stress
import "core:c"
// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
// Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
MAX_ITEMS :: 32
Node :: struct { data: u16, idx: i32, next: int }
crc_byte :: proc(v_in: u16, crc_in: u16) -> u16 { v,crc:=v_in,crc_in;for _ in 0..<8{mix:=(v&1)^(crc&1);v>>=1;if mix!=0{crc^=0x4002};crc>>=1;if mix!=0{crc|=0x8000}else{crc&=0x7fff}};return crc }
crc16 :: proc(v,crc:u16)->u16{return crc_byte(v>>8,crc_byte(v&255,crc))}
compare :: proc(a: ^[MAX_ITEMS+2]Node,x,y:int,complex:bool,seed:u16)->int{if complex{if(a[x].data&0x80)==0{a[x].data=(a[x].data&0xff00)|0x80|((a[x].data^(a[x].data>>8)^seed)&0x7f)};if(a[y].data&0x80)==0{a[y].data=(a[y].data&0xff00)|0x80|((a[y].data^(a[y].data>>8)^seed)&0x7f)};return int(a[x].data&127)-int(a[y].data&127)};a[x].data=(a[x].data&0xff00)|((a[x].data>>8)&255);a[y].data=(a[y].data&0xff00)|((a[y].data>>8)&255);return int(a[x].idx-a[y].idx)}
sort_list :: proc(a: ^[MAX_ITEMS+2]Node,head_in:int,complex:bool,seed:u16)->int{head,width:=head_in,1;for{p,new_head,tail,merges:=head,-1,-1,0;for p>=0{merges++;q,ps:=p,0;for i:=0;i<width;i++{ps++;q=a[q].next;if q<0{break}};qs:=width;for ps>0||(qs>0&&q>=0){e:=0;if ps==0{e=q;q=a[q].next;qs--}else if qs==0||q<0{e=p;p=a[p].next;ps--}else if compare(a,p,q,complex,seed)<=0{e=p;p=a[p].next;ps--}else{e=q;q=a[q].next;qs--};if tail>=0{a[tail].next=e}else{new_head=e};tail=e};p=q};a[tail].next=-1;head=new_head;if merges<=1{return head};width*=2}}
find_node :: proc(a: ^[MAX_ITEMS+2]Node,head_in,idx,data:int)->int{p:=head_in;for p>=0{if(idx>=0&&int(a[p].idx)==idx)||(idx<0&&int(a[p].data&255)==data){return p};p=a[p].next};return -1}
reverse :: proc(a: ^[MAX_ITEMS+2]Node,head:^int){prev,cur:=-1,head^;for cur>=0{next:=a[cur].next;a[cur].next=prev;prev=cur;cur=next};head^=prev}

@(export)
embedded_list_stress :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length!=4 do return -1;rn,seed,find_count,mode:=input[0],input[1],input[2],input[3];if rn<4||rn>MAX_ITEMS||seed<1||seed>255||find_count<0||find_count>32||(mode != -1&&mode != 1) do return -1
 n:=int(rn);tail:=n+1; a:[MAX_ITEMS+2]Node; a[0]=Node{0x8080,0,1};a[tail]=Node{0xffff,0x7fff,-1};for i:=0;i<n;i++{dat:=u16((((seed^i)&15)<<3)|(i&7));a[i+1]=Node{(dat<<8)|dat,0,i+2}};a[n].next=tail
 i:=1;for p:=a[0].next;p!=tail;{if i<n/5{a[p].idx=i32(i);i++}else{pat:=i^int(seed);i++;a[p].idx=i32((((i&7)<<8)|pat)&0x3fff)};p=a[p].next};head:=sort_list(&a,0,false,u16(seed))
 info_idx,info_data:=int(mode),0;result:u16=0;found,missed:=0,0;for k:=0;k<int(find_count);k++{info_data=k&255;got:=find_node(&a,head,info_idx,info_data);reverse(&a,&head);if got<0{missed++;first:=a[head].next;if first>=0{result+=((a[first].data>>8)&1)}}else{found++;if(a[got].data&1)!=0{result+=((a[got].data>>9)&1)};next:=a[got].next;if next>=0{a[got].next=a[next].next;a[next].next=a[head].next;a[head].next=next}};if info_idx>=0{info_idx++}}
 result+=u16(found*4-missed);if mode>0{head=sort_list(&a,head,true,u16(seed))};at:=a[head].next;if at>=0{rem:=a[at].next;a[at].data,a[rem].data=a[rem].data,a[at].data;a[at].idx,a[rem].idx=a[rem].idx,a[at].idx;a[at].next=a[rem].next;a[rem].next=-1;f:=find_node(&a,head,info_idx,info_data);if f<0{f=a[head].next};for f>=0{result=crc16(a[head].data,result);f=a[f].next};a[rem].data,a[at].data=a[at].data,a[rem].data;a[rem].idx,a[at].idx=a[at].idx,a[rem].idx;a[rem].next=a[at].next;a[at].next=rem}
 head=sort_list(&a,head,false,u16(seed));for f:=a[head].next;f>=0;f=a[f].next{result=crc16(a[head].data,result)};if output==nil||capacity<2 do return -2;output[0]=u8(result);output[1]=u8(result>>8);return 2
}
