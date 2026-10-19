module embedded_list_stress
// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
// Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
const max_items = 32
struct Node { mut: data u16 idx i32 next int }
fn crc_byte(value_in u16, crc_in u16) u16 { mut value:=value_in;mut crc:=crc_in;for _ in 0..8{mix:=(value&1)^(crc&1);value>>=1;if mix!=0{crc^=0x4002};crc>>=1;if mix!=0{crc|=0x8000}else{crc&=0x7fff}};return crc }
fn crc16(value u16, crc u16) u16 { return crc_byte(value>>8,crc_byte(value&255,crc)) }
fn compare(mut a [max_items+2]Node,x int,y int,complex bool,seed u16) int { if complex { if(a[x].data&0x80)==0{a[x].data=(a[x].data&0xff00)|0x80|((a[x].data^(a[x].data>>8)^seed)&0x7f)};if(a[y].data&0x80)==0{a[y].data=(a[y].data&0xff00)|0x80|((a[y].data^(a[y].data>>8)^seed)&0x7f)};return int(a[x].data&127)-int(a[y].data&127) };a[x].data=(a[x].data&0xff00)|((a[x].data>>8)&255);a[y].data=(a[y].data&0xff00)|((a[y].data>>8)&255);return int(a[x].idx-a[y].idx) }
fn sort_list(mut a [max_items+2]Node,head_in int,complex bool,seed u16) int { mut head:=head_in;mut width:=1;for {mut p:=head;mut new_head:=-1;mut tail:=-1;mut merges:=0;for p>=0{merges++;mut q:=p;mut psize:=0;for _ in 0..width{psize++;q=a[q].next;if q<0{break}};mut qsize:=width;for psize>0||(qsize>0&&q>=0){mut e:=0;if psize==0{e=q;q=a[q].next;qsize--}else if qsize==0||q<0{e=p;p=a[p].next;psize--}else if compare(mut a,p,q,complex,seed)<=0{e=p;p=a[p].next;psize--}else{e=q;q=a[q].next;qsize--};if tail>=0{a[tail].next=e}else{new_head=e};tail=e};p=q};a[tail].next=-1;head=new_head;if merges<=1{return head};width*=2} }
fn find_node(a [max_items+2]Node,head_in int,idx int,data int) int { mut p:=head_in;for p>=0{if(idx>=0&&int(a[p].idx)==idx)||(idx<0&&int(a[p].data&255)==data){return p};p=a[p].next};return -1 }
fn reverse(mut a [max_items+2]Node,mut head int){mut prev:=-1;mut cur:=head;for cur>=0{next:=a[cur].next;a[cur].next=prev;prev=cur;cur=next};head=prev}

@[export: 'embedded_list_stress']
pub fn embedded_list_stress(input &i64,length usize,output &u8,capacity usize) i64 {
 unsafe {
 if input==nil||length!=4{return -1};rn,seed,find_count,mode:=input[0],input[1],input[2],input[3];if rn<4||rn>max_items||seed<1||seed>255||find_count<0||find_count>32||(mode != -1&&mode != 1){return -1}
 n:=int(rn);tail:=n+1;mut a:=[max_items+2]Node{init:Node{}};a[0]=Node{data:0x8080,idx:0,next:1};a[tail]=Node{data:0xffff,idx:0x7fff,next:-1};for i in 0..n{dat:=u16((((seed^i)&15)<<3)|(i&7));a[i+1]=Node{data:(dat<<8)|dat,idx:0,next:i+2}};a[n].next=tail
 mut idx:=1;mut p:=a[0].next;for p!=tail{if idx<n/5{a[p].idx=i32(idx);idx++}else{pat:=idx^int(seed);idx++;a[p].idx=i32((((idx&7)<<8)|pat)&0x3fff)};p=a[p].next};mut head:=sort_list(mut a,0,false,u16(seed))
 mut info_idx:=int(mode);mut info_data:=0;mut result:=u16(0);mut found:=0;mut missed:=0;for k in 0..int(find_count){info_data=k&255;got:=find_node(a,head,info_idx,info_data);reverse(mut a,mut head);if got<0{missed++;first:=a[head].next;if first>=0{result+=((a[first].data>>8)&1)}}else{found++;if(a[got].data&1)!=0{result+=((a[got].data>>9)&1)};next:=a[got].next;if next>=0{a[got].next=a[next].next;a[next].next=a[head].next;a[head].next=next}};if info_idx>=0{info_idx++}}
 result+=u16(found*4-missed);if mode>0{head=sort_list(mut a,head,true,u16(seed))};at:=a[head].next;if at>=0{rem:=a[at].next;tmp:=a[at].data;a[at].data=a[rem].data;a[rem].data=tmp;ti:=a[at].idx;a[at].idx=a[rem].idx;a[rem].idx=ti;a[at].next=a[rem].next;a[rem].next=-1;mut f:=find_node(a,head,info_idx,info_data);if f<0{f=a[head].next};for f>=0{result=crc16(a[head].data,result);f=a[f].next};tmp=a[rem].data;a[rem].data=a[at].data;a[at].data=tmp;ti=a[rem].idx;a[rem].idx=a[at].idx;a[at].idx=ti;a[rem].next=a[at].next;a[at].next=rem}
 head=sort_list(mut a,head,false,u16(seed));for f:=a[head].next;f>=0;f=a[f].next{result=crc16(a[head].data,result)};if output==nil||capacity<2{return -2};output[0]=u8(result);output[1]=u8(result>>8);return 2
 }
}
