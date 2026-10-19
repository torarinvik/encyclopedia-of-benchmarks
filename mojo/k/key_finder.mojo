from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn key_len(id:Int)->Int:
    if id==0:return 2
    if id==1:return 4
    if id==2:return 3
    if id==3:return 5
    if id==4:return 3
    if id==5:return 4
    if id==6:return 3
    if id==7:return 5
    if id==8:return 4
    if id==9 or id==10:return 4
    if id==11:return 3
    if id==12:return 4
    if id==13:return 3
    if id==14:return 5
    if id==15:return 4
    if id==16:return 6
    if id==17:return 5
    if id==18:return 5
    if id==19:return 4
    if id==20:return 5
    if id==21:return 4
    if id==22:return 4
    return 3
fn key_char(id:Int,j:Int)->Int64:
    if id==0:return 73 if j==0 else 32
    if id==1:return 89 if j==0 else (111 if j==1 else (117 if j==2 else 32))
    if id==2:return 87 if j==0 else 32
    if id==3:return 84 if j==0 else (104 if j==1 else (101 if j==2 else (121 if j==3 else 32)))
    if id==4:return 72 if j==0 else 32
    if id==5:return 83 if j==0 else (104 if j==1 else (101 if j==2 else 32))
    if id==6:return 73 if j==0 else (116 if j==1 else 32)
    if id==7:return 32 if j==0 else (116 if j==1 else (104 if j==2 else (101 if j==3 else 32)))
    if id==8:return 84 if j==0 else (104 if j==1 else (101 if j==2 else 32))
    if id==9:return 32 if j==0 else (111 if j==1 else (102 if j==2 else 32))
    if id==10:return 32 if j==0 else (105 if j==1 else (115 if j==2 else 32))
    if id==11:return 73 if j==0 else (115 if j==1 else 32)
    if id==12:return 32 if j==0 else (97 if j==1 else (109 if j==2 else 32))
    if id==13:return 65 if j==0 else (109 if j==1 else 32)
    if id==14:return 32 if j==0 else (97 if j==1 else (114 if j==2 else (101 if j==3 else 32)))
    if id==15:return 65 if j==0 else (114 if j==1 else (101 if j==2 else 32))
    if id==16:return 32 if j==0 else (104 if j==1 else (97 if j==2 else (118 if j==3 else (101 if j==4 else 32))))
    if id==17:return 72 if j==0 else (97 if j==1 else (118 if j==2 else (101 if j==3 else 32)))
    if id==18:return 32 if j==0 else (104 if j==1 else (97 if j==2 else (115 if j==3 else 32)))
    if id==19:return 72 if j==0 else (97 if j==1 else (115 if j==2 else 32))
    if id==20:return 32 if j==0 else (109 if j==1 else (97 if j==2 else (121 if j==3 else 32)))
    if id==21:return 77 if j==0 else (97 if j==1 else (121 if j==2 else 32))
    if id==22:return 32 if j==0 else (98 if j==1 else (101 if j==2 else 32))
    return 66 if j==0 else (101 if j==1 else 32)
@export("key_finder")
fn key_finder(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>258 or a[0]<0 or a[0]>256 or n!=c_size_t(a[0]+1):return -1
    let count=Int(a[0])
    for i in range(count):if a[i+1]<32 or a[i+1]>126 or (a[i+1]>=48 and a[i+1]<=57):return -1
    for key in range(26):
        for start in range(count):
            for id in range(24):
                let plen=key_len(id)
                if start+plen>count:continue
                var good=True
                for j in range(plen):
                    var ch=a[start+j+1]
                    if ch>=65 and ch<=90:ch=65+(ch-65+key)%26
                    elif ch>=97 and ch<=122:ch=97+(ch-97+key)%26
                    if ch!=key_char(id,j):good=False;break
                if good:return key
    return 0
