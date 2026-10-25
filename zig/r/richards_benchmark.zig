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

const Packet = struct { link: usize = 0, id: usize = 0, kind: i32 = 0, a1: i32 = 0, a2: [4]i32 = .{0} ** 4 };
const Task = struct { link: usize = 0, id: usize = 0, priority: i32 = 0, queue: usize = 0, state: i32 = 0, v1: i64 = 0, v2: i64 = 0 };
const Scheduler = struct {
    packets: [9]Packet = .{.{}} ** 9,
    tasks: [7]Task = .{.{}} ** 7,
    packet_used: usize = 0,
    task_list: usize = 0,
    current: usize = 0,
    task_id: usize = 0,
    packet_count: i64 = 0,
    hold_count: i64 = 0,
    v1: i64 = 0,
    v2: i64 = 0,

    fn makePacket(self: *Scheduler, link: usize, id: usize, kind: i32) usize {
        self.packet_used += 1;
        const index = self.packet_used;
        self.packets[index] = .{ .link = link, .id = id, .kind = kind };
        return index;
    }
    fn makeTask(self: *Scheduler, id: usize, priority: i32, queue: usize, state: i32, a: i64, b: i64) void {
        self.tasks[id] = .{ .link = self.task_list, .id = id, .priority = priority, .queue = queue, .state = state, .v1 = a, .v2 = b };
        self.task_list = id;
    }
    fn appendPacket(self: *Scheduler, packet: usize, head: usize) usize {
        self.packets[packet].link = 0;
        if (head == 0) return packet;
        var tail = head;
        while (self.packets[tail].link != 0) tail = self.packets[tail].link;
        self.packets[tail].link = packet;
        return head;
    }
    fn queuePacket(self: *Scheduler, packet: usize) usize {
        const destination = self.packets[packet].id;
        self.packet_count += 1;
        self.packets[packet].link = 0;
        self.packets[packet].id = self.task_id;
        if (self.tasks[destination].queue == 0) {
            self.tasks[destination].queue = packet;
            self.tasks[destination].state |= PKT;
            if (self.tasks[destination].priority > self.tasks[self.task_id].priority) return destination;
        } else {
            const head = self.tasks[destination].queue;
            self.tasks[destination].queue = self.appendPacket(packet, head);
        }
        return self.current;
    }
    fn releaseTask(self: *Scheduler, destination: usize) usize {
        self.tasks[destination].state &= ~HOLD;
        if (self.tasks[destination].priority > self.tasks[self.task_id].priority) return destination;
        return self.current;
    }
    fn waitTask(self: *Scheduler) usize { self.tasks[self.task_id].state |= WAIT; return self.task_id; }
    fn holdTask(self: *Scheduler) usize {
        self.hold_count += 1;
        self.tasks[self.task_id].state |= HOLD;
        return self.tasks[self.task_id].link;
    }
    fn runTask(self: *Scheduler, packet_in: usize) usize {
        var packet = packet_in;
        if (self.task_id == IDLE) {
            self.v2 -= 1;
            if (self.v2 == 0) return self.holdTask();
            if ((self.v1 & 1) == 0) { self.v1 = (self.v1 >> 1) & 32767; return self.releaseTask(DEVICE_A); }
            self.v1 = ((self.v1 >> 1) & 32767) ^ 0xD008;
            return self.releaseTask(DEVICE_B);
        }
        if (self.task_id == WORK) {
            if (packet == 0) return self.waitTask();
            self.v1 = @as(i64, @intCast(HANDLER_A + HANDLER_B)) - self.v1;
            self.packets[packet].id = @intCast(self.v1);
            self.packets[packet].a1 = 0;
            for (0..4) |index| {
                self.v2 += 1;
                if (self.v2 > 26) self.v2 = 1;
                self.packets[packet].a2[index] = @as(i32, @intCast(64 + self.v2));
            }
            return self.queuePacket(packet);
        }
        if (self.task_id == HANDLER_A or self.task_id == HANDLER_B) {
            if (packet != 0) {
                if (self.packets[packet].kind == K_WORK) self.v1 = @intCast(self.appendPacket(packet, @intCast(self.v1)))
                else self.v2 = @intCast(self.appendPacket(packet, @intCast(self.v2)));
            }
            if (self.v1 != 0) {
                const work_packet: usize = @intCast(self.v1);
                const count: usize = @intCast(self.packets[work_packet].a1);
                if (count > 3) {
                    self.v1 = @intCast(self.packets[work_packet].link);
                    return self.queuePacket(work_packet);
                }
                if (self.v2 != 0) {
                    const device_packet: usize = @intCast(self.v2);
                    self.v2 = @intCast(self.packets[device_packet].link);
                    self.packets[device_packet].a1 = self.packets[work_packet].a2[count];
                    self.packets[work_packet].a1 = @intCast(count + 1);
                    return self.queuePacket(device_packet);
                }
            }
            return self.waitTask();
        }
        if (packet == 0) {
            if (self.v1 == 0) return self.waitTask();
            packet = @intCast(self.v1);
            self.v1 = 0;
            return self.queuePacket(packet);
        }
        self.v1 = @intCast(packet);
        return self.holdTask();
    }
    fn schedule(self: *Scheduler) bool {
        while (self.current != 0) {
            const task_id = self.current;
            var packet: usize = 0;
            if (self.tasks[task_id].state == WAITPKT) {
                packet = self.tasks[task_id].queue;
                self.tasks[task_id].queue = self.packets[packet].link;
                self.tasks[task_id].state = if (self.tasks[task_id].queue == 0) RUN else RUNPKT;
            }
            const state = self.tasks[task_id].state;
            if (state == RUN or state == RUNPKT) {
                self.task_id = self.tasks[task_id].id;
                self.v1 = self.tasks[task_id].v1;
                self.v2 = self.tasks[task_id].v2;
                self.current = self.runTask(packet);
                self.tasks[task_id].v1 = self.v1;
                self.tasks[task_id].v2 = self.v2;
            } else if (state == WAITING or state == HOLDING or state == HOLDPKT or state == HOLDWAIT or state == HOLDWAITPKT) {
                self.current = self.tasks[task_id].link;
            } else return false;
        }
        return true;
    }
};

pub export fn richards_benchmark(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 1) return -1;
    const iterations = input[0];
    if (iterations < 1 or iterations > MAX_ITERATIONS) return -1;
    var s = Scheduler{};
    var work = s.makePacket(0, 0, K_WORK);
    work = s.makePacket(work, 0, K_WORK);
    s.makeTask(IDLE, 0, 0, RUN, 1, iterations);
    s.makeTask(WORK, 1000, work, WAITPKT, @intCast(HANDLER_A), 0);
    var handler_a = s.makePacket(0, DEVICE_A, K_DEV);
    handler_a = s.makePacket(handler_a, DEVICE_A, K_DEV);
    handler_a = s.makePacket(handler_a, DEVICE_A, K_DEV);
    s.makeTask(HANDLER_A, 2000, handler_a, WAITPKT, 0, 0);
    var handler_b = s.makePacket(0, DEVICE_B, K_DEV);
    handler_b = s.makePacket(handler_b, DEVICE_B, K_DEV);
    handler_b = s.makePacket(handler_b, DEVICE_B, K_DEV);
    s.makeTask(HANDLER_B, 3000, handler_b, WAITPKT, 0, 0);
    s.makeTask(DEVICE_A, 4000, 0, WAITING, 0, 0);
    s.makeTask(DEVICE_B, 5000, 0, WAITING, 0, 0);
    s.current = s.task_list;
    if (!s.schedule()) return -1;
    return s.packet_count * 2_147_483_648 + s.hold_count;
}
