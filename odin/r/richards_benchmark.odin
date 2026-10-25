package richards_benchmark
import "core:c"

MAX_ITERATIONS :: 1_000_000
IDLE, WORK, HANDLER_A, HANDLER_B, DEVICE_A, DEVICE_B :: 1, 2, 3, 4, 5, 6
K_DEV, K_WORK :: 1000, 1001
PKT, WAIT, HOLD :: 1, 2, 4
RUN, RUNPKT, WAITING, WAITPKT :: 0, 1, 2, 3
HOLDING, HOLDPKT, HOLDWAIT, HOLDWAITPKT :: 4, 5, 6, 7
Packet :: struct {link, id, kind, a1:int, a2:[4]int}
Task :: struct {link, id, priority, queue, state:int, v1, v2:i64}
Scheduler :: struct {
    packets:[9]Packet,
    tasks:[7]Task,
    packet_used, tasklist, current, taskid, packet_count, hold_count:int,
    v1, v2:i64,
}

make_packet :: proc(s:^Scheduler, link, id, kind:int)->int {
    s.packet_used += 1
    s.packets[s.packet_used] = Packet{link=link,id=id,kind=kind}
    return s.packet_used
}
make_task :: proc(s:^Scheduler, id, priority, queue, state:int, a,b:i64) {
    s.tasks[id] = Task{link=s.tasklist,id=id,priority=priority,queue=queue,state=state,v1=a,v2=b}
    s.tasklist = id
}
append_packet :: proc(s:^Scheduler, packet:int, head:int)->int {
    s.packets[packet].link = 0
    if head == 0 do return packet
    tail := head
    for s.packets[tail].link != 0 { tail = s.packets[tail].link }
    s.packets[tail].link = packet
    return head
}
queue_packet :: proc(s:^Scheduler, packet:int)->int {
    destination := s.packets[packet].id
    s.packet_count += 1
    s.packets[packet].link = 0
    s.packets[packet].id = s.taskid
    if s.tasks[destination].queue == 0 {
        s.tasks[destination].queue = packet
        s.tasks[destination].state |= PKT
        if s.tasks[destination].priority > s.tasks[s.taskid].priority do return destination
    } else { s.tasks[destination].queue = append_packet(s,packet,s.tasks[destination].queue) }
    return s.current
}
release_task :: proc(s:^Scheduler,destination:int)->int {
    s.tasks[destination].state &= ~HOLD
    if s.tasks[destination].priority > s.tasks[s.taskid].priority do return destination
    return s.current
}
wait_task :: proc(s:^Scheduler)->int { s.tasks[s.taskid].state |= WAIT; return s.taskid }
hold_task :: proc(s:^Scheduler)->int { s.hold_count+=1;s.tasks[s.taskid].state|=HOLD;return s.tasks[s.taskid].link }
run_task :: proc(s:^Scheduler, packet:int)->int {
    if s.taskid==IDLE {
        s.v2-=1
        if s.v2==0 do return hold_task(s)
        if (s.v1&1)==0 { s.v1=(s.v1>>1)&32767;return release_task(s,DEVICE_A) }
        s.v1=((s.v1>>1)&32767)^0xd008
        return release_task(s,DEVICE_B)
    }
    if s.taskid==WORK {
        if packet==0 do return wait_task(s)
        s.v1=i64(HANDLER_A+HANDLER_B)-s.v1
        s.packets[packet].id=int(s.v1);s.packets[packet].a1=0
        for i:=0; i<=3; i+=1 { s.v2+=1;if s.v2>26 do s.v2=1;s.packets[packet].a2[i]=65+int(s.v2)-1 }
        return queue_packet(s,packet)
    }
    if s.taskid==HANDLER_A || s.taskid==HANDLER_B {
        if packet!=0 {
            if s.packets[packet].kind==K_WORK { s.v1=i64(append_packet(s,packet,int(s.v1))) }
            else { s.v2=i64(append_packet(s,packet,int(s.v2))) }
        }
        if s.v1!=0 {
            work_packet:=int(s.v1);count:=s.packets[work_packet].a1
            if count>3 { s.v1=i64(s.packets[work_packet].link);return queue_packet(s,work_packet) }
            if s.v2!=0 {
                device_packet:=int(s.v2);s.v2=i64(s.packets[device_packet].link)
                s.packets[device_packet].a1=s.packets[work_packet].a2[count]
                s.packets[work_packet].a1=count+1
                return queue_packet(s,device_packet)
            }
        }
        return wait_task(s)
    }
    if packet==0 { if s.v1==0 do return wait_task(s);packet=int(s.v1);s.v1=0;return queue_packet(s,packet) }
    s.v1=i64(packet);return hold_task(s)
}
schedule :: proc(s:^Scheduler)->bool {
    for s.current!=0 {
        packet:=0;task_id:=s.current
        if s.tasks[task_id].state==WAITPKT {
            packet=s.tasks[task_id].queue
            s.tasks[task_id].queue=s.packets[packet].link
            if s.tasks[task_id].queue==0 { s.tasks[task_id].state=RUN } else { s.tasks[task_id].state=RUNPKT }
        }
        state:=s.tasks[task_id].state
        if state==RUN || state==RUNPKT {
            s.taskid=task_id;s.v1=s.tasks[task_id].v1;s.v2=s.tasks[task_id].v2
            s.current=run_task(s,packet)
            s.tasks[task_id].v1=s.v1;s.tasks[task_id].v2=s.v2
        } else if state==WAITING || state==HOLDING || state==HOLDPKT || state==HOLDWAIT || state==HOLDWAITPKT {
            s.current=s.tasks[task_id].link
        } else { return false }
    }
    return true
}

@(export)
richards_benchmark :: proc "c" (input:[^]i64,length:c.size_t)->i64 {
    if input==nil || length!=1 do return -1
    if input[0]<1 || input[0]>MAX_ITERATIONS do return -1
    s:Scheduler
    work:=make_packet(&s,0,0,K_WORK);work=make_packet(&s,work,0,K_WORK)
    make_task(&s,IDLE,0,0,RUN,1,input[0]);make_task(&s,WORK,1000,work,WAITPKT,HANDLER_A,0)
    ha:=make_packet(&s,0,DEVICE_A,K_DEV);ha=make_packet(&s,ha,DEVICE_A,K_DEV);ha=make_packet(&s,ha,DEVICE_A,K_DEV);make_task(&s,HANDLER_A,2000,ha,WAITPKT,0,0)
    hb:=make_packet(&s,0,DEVICE_B,K_DEV);hb=make_packet(&s,hb,DEVICE_B,K_DEV);hb=make_packet(&s,hb,DEVICE_B,K_DEV);make_task(&s,HANDLER_B,3000,hb,WAITPKT,0,0)
    make_task(&s,DEVICE_A,4000,0,WAITING,0,0);make_task(&s,DEVICE_B,5000,0,WAITING,0,0)
    s.current=s.tasklist
    if !schedule(&s) do return -1
    return i64(s.packet_count)*2_147_483_648+s.hold_count
}
