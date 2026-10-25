const MAX_ITERATIONS: i64 = 1_000_000;
const IDLE: usize = 1;
const WORK: usize = 2;
const HANDLER_A: usize = 3;
const HANDLER_B: usize = 4;
const DEVICE_A: usize = 5;
const DEVICE_B: usize = 6;
const K_DEV: i32 = 1000;
const K_WORK: i32 = 1001;
const PKT: i32 = 1;
const WAIT: i32 = 2;
const HOLD: i32 = 4;
const RUN: i32 = 0;
const RUNPKT: i32 = 1;
const WAITING: i32 = 2;
const WAITPKT: i32 = 3;
const HOLDING: i32 = 4;
const HOLDPKT: i32 = 5;
const HOLDWAIT: i32 = 6;
const HOLDWAITPKT: i32 = 7;

#[derive(Clone, Copy, Default)]
struct Packet { link: usize, id: usize, kind: i32, a1: i32, a2: [i32; 4] }
#[derive(Clone, Copy, Default)]
struct Task { link: usize, id: usize, priority: i32, queue: usize, state: i32, v1: i64, v2: i64 }
struct Scheduler {
    packets: [Packet; 9],
    tasks: [Task; 7],
    packet_used: usize,
    task_list: usize,
    current: usize,
    task_id: usize,
    packet_count: i64,
    hold_count: i64,
    v1: i64,
    v2: i64,
}

impl Scheduler {
    fn new() -> Self {
        Self { packets: [Packet::default(); 9], tasks: [Task::default(); 7],
               packet_used: 0, task_list: 0, current: 0, task_id: 0,
               packet_count: 0, hold_count: 0, v1: 0, v2: 0 }
    }
    fn make_packet(&mut self, link: usize, id: usize, kind: i32) -> usize {
        self.packet_used += 1;
        let index = self.packet_used;
        self.packets[index] = Packet { link, id, kind, a1: 0, a2: [0; 4] };
        index
    }
    fn make_task(&mut self, id: usize, priority: i32, queue: usize, state: i32, a: i64, b: i64) {
        self.tasks[id] = Task { link: self.task_list, id, priority, queue, state, v1: a, v2: b };
        self.task_list = id;
    }
    fn append_packet(&mut self, packet: usize, head: usize) -> usize {
        self.packets[packet].link = 0;
        if head == 0 { return packet; }
        let mut tail = head;
        while self.packets[tail].link != 0 { tail = self.packets[tail].link; }
        self.packets[tail].link = packet;
        head
    }
    fn queue_packet(&mut self, packet: usize) -> usize {
        let destination = self.packets[packet].id;
        self.packet_count += 1;
        self.packets[packet].link = 0;
        self.packets[packet].id = self.task_id;
        if self.tasks[destination].queue == 0 {
            self.tasks[destination].queue = packet;
            self.tasks[destination].state |= PKT;
            if self.tasks[destination].priority > self.tasks[self.task_id].priority { return destination; }
        } else {
            let head = self.tasks[destination].queue;
            let new_head = self.append_packet(packet, head);
            self.tasks[destination].queue = new_head;
        }
        self.current
    }
    fn release(&mut self, destination: usize) -> usize {
        self.tasks[destination].state &= !HOLD;
        if self.tasks[destination].priority > self.tasks[self.task_id].priority { destination } else { self.current }
    }
    fn wait(&mut self) -> usize { self.tasks[self.task_id].state |= WAIT; self.task_id }
    fn hold(&mut self) -> usize {
        self.hold_count += 1;
        self.tasks[self.task_id].state |= HOLD;
        self.tasks[self.task_id].link
    }
    fn run_task(&mut self, mut packet: usize) -> usize {
        if self.task_id == IDLE {
            self.v2 -= 1;
            if self.v2 == 0 { return self.hold(); }
            if self.v1 & 1 == 0 { self.v1 = (self.v1 >> 1) & 32767; return self.release(DEVICE_A); }
            self.v1 = ((self.v1 >> 1) & 32767) ^ 0xD008;
            return self.release(DEVICE_B);
        }
        if self.task_id == WORK {
            if packet == 0 { return self.wait(); }
            self.v1 = (HANDLER_A + HANDLER_B) as i64 - self.v1;
            self.packets[packet].id = self.v1 as usize;
            self.packets[packet].a1 = 0;
            for index in 0..4 {
                self.v2 += 1;
                if self.v2 > 26 { self.v2 = 1; }
                self.packets[packet].a2[index] = 64 + self.v2 as i32;
            }
            return self.queue_packet(packet);
        }
        if self.task_id == HANDLER_A || self.task_id == HANDLER_B {
            if packet != 0 {
                if self.packets[packet].kind == K_WORK {
                    self.v1 = self.append_packet(packet, self.v1 as usize) as i64;
                } else {
                    self.v2 = self.append_packet(packet, self.v2 as usize) as i64;
                }
            }
            if self.v1 != 0 {
                let work_packet = self.v1 as usize;
                let count = self.packets[work_packet].a1 as usize;
                if count > 3 {
                    self.v1 = self.packets[work_packet].link as i64;
                    return self.queue_packet(work_packet);
                }
                if self.v2 != 0 {
                    let device_packet = self.v2 as usize;
                    self.v2 = self.packets[device_packet].link as i64;
                    self.packets[device_packet].a1 = self.packets[work_packet].a2[count];
                    self.packets[work_packet].a1 = count as i32 + 1;
                    return self.queue_packet(device_packet);
                }
            }
            return self.wait();
        }
        if packet == 0 {
            if self.v1 == 0 { return self.wait(); }
            packet = self.v1 as usize;
            self.v1 = 0;
            return self.queue_packet(packet);
        }
        self.v1 = packet as i64;
        self.hold()
    }
    fn schedule(&mut self) -> bool {
        while self.current != 0 {
            let task_id = self.current;
            let mut packet = 0;
            if self.tasks[task_id].state == WAITPKT {
                packet = self.tasks[task_id].queue;
                self.tasks[task_id].queue = self.packets[packet].link;
                self.tasks[task_id].state = if self.tasks[task_id].queue == 0 { RUN } else { RUNPKT };
            }
            let state = self.tasks[task_id].state;
            if state == RUN || state == RUNPKT {
                self.task_id = self.tasks[task_id].id;
                self.v1 = self.tasks[task_id].v1;
                self.v2 = self.tasks[task_id].v2;
                self.current = self.run_task(packet);
                self.tasks[task_id].v1 = self.v1;
                self.tasks[task_id].v2 = self.v2;
            } else if state == WAITING || state == HOLDING || state == HOLDPKT || state == HOLDWAIT || state == HOLDWAITPKT {
                self.current = self.tasks[task_id].link;
            } else { return false; }
        }
        true
    }
}

#[no_mangle]
pub unsafe extern "C" fn richards_benchmark(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let iterations = unsafe { *input };
    if !(1..=MAX_ITERATIONS).contains(&iterations) { return -1; }
    let mut scheduler = Scheduler::new();
    let mut work = scheduler.make_packet(0, 0, K_WORK);
    work = scheduler.make_packet(work, 0, K_WORK);
    scheduler.make_task(IDLE, 0, 0, RUN, 1, iterations);
    scheduler.make_task(WORK, 1000, work, WAITPKT, HANDLER_A as i64, 0);
    let mut handler_a = scheduler.make_packet(0, DEVICE_A, K_DEV);
    handler_a = scheduler.make_packet(handler_a, DEVICE_A, K_DEV);
    handler_a = scheduler.make_packet(handler_a, DEVICE_A, K_DEV);
    scheduler.make_task(HANDLER_A, 2000, handler_a, WAITPKT, 0, 0);
    let mut handler_b = scheduler.make_packet(0, DEVICE_B, K_DEV);
    handler_b = scheduler.make_packet(handler_b, DEVICE_B, K_DEV);
    handler_b = scheduler.make_packet(handler_b, DEVICE_B, K_DEV);
    scheduler.make_task(HANDLER_B, 3000, handler_b, WAITPKT, 0, 0);
    scheduler.make_task(DEVICE_A, 4000, 0, WAITING, 0, 0);
    scheduler.make_task(DEVICE_B, 5000, 0, WAITING, 0, 0);
    scheduler.current = scheduler.task_list;
    if !scheduler.schedule() { return -1; }
    scheduler.packet_count * (1_i64 << 31) + scheduler.hold_count
}
