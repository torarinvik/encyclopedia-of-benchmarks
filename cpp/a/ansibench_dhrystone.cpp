/* Bounded Dhrystone 2.1 core profile; upstream notice is in package LICENSE. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { IDENT_1=0, IDENT_2=1, IDENT_3=2, IDENT_4=3, IDENT_5=4 };
typedef struct { int ptr, discr, enum_comp, int_comp; char str[31]; } Record;
typedef struct {
    int int_glob, bool_glob, ch1, ch2;
    int arr1[50], arr2[50][50];
    Record records[2];
} State;

static void copy_string(char dst[31], const char *src) { size_t i=0; do { dst[i]=src[i]; } while (src[i++]!='\0'); }
static int strcmp30(const char a[31], const char b[31]) {
    for (size_t i=0;i<31;i++) { unsigned char x=(unsigned char)a[i], y=(unsigned char)b[i]; if(x!=y)return x<y?-1:1; if(x==0)return 0; }
    return 0;
}
static int func1(State *s, int a, int b) { if(a!=b)return IDENT_1; s->ch1=a; return IDENT_2; }
static int func3(int e) { return e==IDENT_3; }
static void proc7(int a,int b,int *out) { *out=b+(a+2); }
static void proc6(State *s,int value,int *out) {
    *out=value;
    if(!func3(value))*out=IDENT_4;
    switch(value) {
    case IDENT_1:*out=IDENT_1;break;
    case IDENT_2:*out=s->int_glob>100?IDENT_1:IDENT_4;break;
    case IDENT_3:*out=IDENT_2;break;
    case IDENT_4:break;
    case IDENT_5:*out=IDENT_3;break;
    }
}
static void proc3(State *s,int *ref) {
    if(s->records[0].ptr>=0)*ref=s->records[0].ptr;
    proc7(10,s->int_glob,&s->records[0].int_comp);
}
static void proc1(State *s) {
    int next=s->records[0].ptr;
    s->records[next]=s->records[0];
    s->records[0].int_comp=5;
    s->records[next].int_comp=s->records[0].int_comp;
    s->records[next].ptr=s->records[0].ptr;
    proc3(s,&s->records[next].ptr);
    if(s->records[next].discr==IDENT_1) {
        s->records[next].int_comp=6;
        proc6(s,s->records[0].enum_comp,&s->records[next].enum_comp);
        s->records[next].ptr=s->records[0].ptr;
        proc7(s->records[next].int_comp,10,&s->records[next].int_comp);
    } else s->records[0]=s->records[next];
}
static void proc2(State *s,int *value) {
    int loc=*value+10, e;
    do { if(s->ch1=='A') { loc-=1; *value=loc-s->int_glob; e=IDENT_1; } else e=IDENT_2; } while(e!=IDENT_1);
}
static void proc4(State *s) { int local=s->ch1=='A'; s->bool_glob=local|s->bool_glob; s->ch2='B'; }
static void proc5(State *s) { s->ch1='A'; s->bool_glob=0; }
static void proc8(State *s,int a,int b) {
    int loc=a+5; s->arr1[loc]=b; s->arr1[loc+1]=s->arr1[loc]; s->arr1[loc+30]=loc;
    for(int i=loc;i<=loc+1;i++)s->arr2[loc][i]=loc;
    s->arr2[loc][loc-1]+=1; s->arr2[loc+20][loc]=s->arr1[loc]; s->int_glob=5;
}
static int func2(State *s,const char a[31],const char b[31]) {
    int loc=2, ch=0;
    while(loc<=2) if(func1(s,a[loc],b[loc+1])==IDENT_1) { ch='A';loc+=1; }
    if(ch>='W'&&ch<'Z')loc=7;
    if(ch=='R')return 1;
    if(strcmp30(a,b)>0) {loc+=7;s->int_glob=loc;return 1;}
    return 0;
}

static void put_u64le(uint8_t *out,size_t *at,uint64_t value) {
    for(unsigned i=0;i<8;i++)out[(*at)++]=(uint8_t)(value>>(8*i));
}
extern "C" int64_t ansibench_dhrystone(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if(input==NULL||length!=1||input[0]<1||input[0]>8)return -1;
    State s={0}; Record *ptr=&s.records[0], *next=&s.records[1];
    ptr->ptr=1;ptr->discr=IDENT_1;ptr->enum_comp=IDENT_3;ptr->int_comp=40;
    copy_string(ptr->str,"DHRYSTONE PROGRAM, SOME STRING");
    char str1[31]={0},str2[31]={0};
    copy_string(str1,"DHRYSTONE PROGRAM, 1'ST STRING");
    s.arr2[8][7]=10;
    int int1=0,int2=0,int3=0,enum_loc=0,func2_false=0;
    for(int run=1;run<=input[0];run++) {
        proc5(&s);proc4(&s);int1=2;int2=3;
        copy_string(str2,"DHRYSTONE PROGRAM, 2'ND STRING");enum_loc=IDENT_2;
        func2_false=!func2(&s,str1,str2);
        while(int1<int2) {int3=5*int1-int2;proc7(int1,int2,&int3);int1+=1;}
        proc8(&s,int1,int3);proc1(&s);
        for(int ch='A';ch<=s.ch2;ch++)if(enum_loc==func1(&s,ch,'C')) {
            proc6(&s,IDENT_1,&enum_loc);copy_string(str2,"DHRYSTONE PROGRAM, 3'RD STRING");int2=run;s.int_glob=run;
        }
        int2=int2*int1;int1=int2/int3;int2=7*(int2-int3)-int1;proc2(&s,&int1);
    }
    if(output==NULL||capacity<19)return -2;
    uint8_t staged[19];size_t at=0;
    int values[19]={s.int_glob,s.bool_glob,s.ch1,s.ch2,s.arr1[8],s.arr2[8][7],
        ptr->discr,ptr->enum_comp,ptr->int_comp,ptr->ptr,next->discr,next->enum_comp,
        next->int_comp,next->ptr,int1,int2,int3,enum_loc,func2_false};
    for(size_t i=0;i<19;i++)staged[at++]=(uint8_t)values[i];
    memcpy(output,staged,sizeof(staged));return (int64_t)sizeof(staged);
}
