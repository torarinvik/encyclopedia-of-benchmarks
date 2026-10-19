module embedded_list_stress;
// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
// Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
const int MAX_ITEMS = 32;
struct Node { ushort data; int idx; int next; }

fn ushort crc_byte(ushort value, ushort crc) { for(int b=0;b<8;b++){ushort mix=(ushort)((value&1)^(crc&1));value>>=1;if(mix!=0)crc^=0x4002;crc>>=1;if(mix!=0)crc|=0x8000;else crc&=0x7fff;}return crc; }
fn ushort crc16(ushort value,ushort crc){crc=crc_byte((ushort)(value&255),crc);return crc_byte((ushort)(value>>8),crc);}
fn int compare(Node* a,int x,int y,bool complex,ushort seed){if(complex){if((a[x].data&0x80)==0)a[x].data=(ushort)((a[x].data&0xff00)|0x80|((a[x].data^(a[x].data>>8)^seed)&0x7f));if((a[y].data&0x80)==0)a[y].data=(ushort)((a[y].data&0xff00)|0x80|((a[y].data^(a[y].data>>8)^seed)&0x7f));return (int)(a[x].data&127)-(int)(a[y].data&127);}a[x].data=(ushort)((a[x].data&0xff00)|((a[x].data>>8)&255));a[y].data=(ushort)((a[y].data&0xff00)|((a[y].data>>8)&255));return a[x].idx-a[y].idx;}
fn int sort_list(Node* a,int head,bool complex,ushort seed){int width=1;for(;;){int p=head,new_head=-1,tail=-1,merges=0;while(p>=0){merges++;int q=p,ps=0;for(int i=0;i<width;i++){ps++;q=a[q].next;if(q<0)break;}int qs=width;while(ps>0||(qs>0&&q>=0)){int e;if(ps==0){e=q;q=a[q].next;qs--;}else if(qs==0||q<0){e=p;p=a[p].next;ps--;}else if(compare(a,p,q,complex,seed)<=0){e=p;p=a[p].next;ps--;}else{e=q;q=a[q].next;qs--;}if(tail>=0)a[tail].next=e;else new_head=e;tail=e;}p=q;}a[tail].next=-1;head=new_head;if(merges<=1)return head;width*=2;}}
fn int find_node(Node* a,int head,int idx,int data){for(int p=head;p>=0;p=a[p].next)if(idx>=0?a[p].idx==idx:(a[p].data&255)==data)return p;return -1;}
fn void reverse(Node* a,int* head){int prev=-1,cur=*head;while(cur>=0){int next=a[cur].next;a[cur].next=prev;prev=cur;cur=next;}*head=prev;}
fn long embedded_list_stress(long* input,usz length,char* output,usz capacity) @export("embedded_list_stress") {
 if(input==null||length!=4)return -1;long rn=input[0],seed=input[1],find_count=input[2],mode=input[3];if(rn<4||rn>MAX_ITEMS||seed<1||seed>255||find_count<0||find_count>32||!(mode==-1||mode==1))return -1;
 int n=(int)rn,head=0,tail=n+1;Node[MAX_ITEMS+2] a={};a[0].data=0x8080;a[0].idx=0;a[0].next=1;a[tail].data=0xffff;a[tail].idx=0x7fff;a[tail].next=-1;for(int i=0;i<n;i++){ushort dat=(ushort)(((((ushort)seed^(ushort)i)&15)<<3)|(i&7));a[i+1].data=(ushort)((dat<<8)|dat);a[i+1].next=i+2;}a[n].next=tail;
 int i=1;for(int p=a[0].next;p!=tail;p=a[p].next){if(i<n/5)a[p].idx=i++;else{ushort pat=(ushort)(i++^(int)seed);a[p].idx=(((i&7)<<8)|pat)&0x3fff;}}head=sort_list(&a[0],head,false,(ushort)seed);
 int info_idx=(int)mode,info_data=0;ushort result=0;long found=0,missed=0;for(int k=0;k<(int)find_count;k++){info_data=k&255;int got=find_node(&a[0],head,info_idx,info_data);reverse(&a[0],&head);if(got<0){missed++;int first=a[head].next;if(first>=0)result=(ushort)(result+((a[first].data>>8)&1));}else{found++;if(a[got].data&1)result=(ushort)(result+((a[got].data>>9)&1));int next=a[got].next;if(next>=0){a[got].next=a[next].next;a[next].next=a[head].next;a[head].next=next;}}if(info_idx>=0)info_idx++;}
 result=(ushort)(result+found*4-missed);if(mode>0)head=sort_list(&a[0],head,true,(ushort)seed);int at=a[head].next;if(at>=0){int rem=a[at].next;ushort td=a[at].data;a[at].data=a[rem].data;a[rem].data=td;int ti=a[at].idx;a[at].idx=a[rem].idx;a[rem].idx=ti;a[at].next=a[rem].next;a[rem].next=-1;int f=find_node(&a[0],head,info_idx,info_data);if(f<0)f=a[head].next;while(f>=0){result=crc16(a[head].data,result);f=a[f].next;}td=a[rem].data;a[rem].data=a[at].data;a[at].data=td;ti=a[rem].idx;a[rem].idx=a[at].idx;a[at].idx=ti;a[rem].next=a[at].next;a[at].next=rem;}
 head=sort_list(&a[0],head,false,(ushort)seed);int f=a[head].next;while(f>=0){result=crc16(a[head].data,result);f=a[f].next;}if(output==null||capacity<2)return -2;output[0]=(char)(result&255);output[1]=(char)(result>>8);return 2;
}
