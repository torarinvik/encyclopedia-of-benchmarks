module main

const max_iterations = i64(1000000)
const idle = 1
const work = 2
const handler_a = 3
const handler_b = 4
const device_a = 5
const device_b = 6
const k_dev = 1000
const k_work = 1001
const pkt_bit = 1
const wait_bit = 2
const hold_bit = 4
const run_state = 0
const run_pkt = 1
const wait_state = 2
const wait_pkt = 3
const hold_state = 4
const hold_pkt = 5
const hold_wait = 6
const hold_wait_pkt = 7

struct Packet { link int; id int; kind int; a1 int; a2 [4]int }
struct Task { link int; id int; priority int; queue int; state int; v1 i64; v2 i64 }
struct Scheduler {
	mut:
		packets [9]Packet
		tasks [7]Task
		packet_used int
		task_list int
		current int
		task_id int
		packet_count int
		hold_count int
		v1 i64
		v2 i64
}

fn (mut s Scheduler) make_packet(link int, id int, kind int) int {
	s.packet_used++
	s.packets[s.packet_used] = Packet{link, id, kind, 0, [4]int{}}
	return s.packet_used
}
fn (mut s Scheduler) make_task(id int, priority int, queue int, state int, a i64, b i64) {
	s.tasks[id] = Task{s.task_list, id, priority, queue, state, a, b}
	s.task_list = id
}
fn (mut s Scheduler) append_packet(packet int, head int) int {
	s.packets[packet].link = 0
	if head == 0 { return packet }
	mut tail := head
	for s.packets[tail].link != 0 { tail = s.packets[tail].link }
	s.packets[tail].link = packet
	return head
}
fn (mut s Scheduler) queue_packet(packet int) int {
	destination := s.packets[packet].id
	s.packet_count++
	s.packets[packet].link = 0
	s.packets[packet].id = s.task_id
	if s.tasks[destination].queue == 0 {
		s.tasks[destination].queue = packet
		s.tasks[destination].state |= pkt_bit
		if s.tasks[destination].priority > s.tasks[s.task_id].priority { return destination }
	} else {
		head := s.tasks[destination].queue
		s.tasks[destination].queue = s.append_packet(packet, head)
	}
	return s.current
}
fn (mut s Scheduler) release_task(destination int) int {
	s.tasks[destination].state &= ~hold_bit
	if s.tasks[destination].priority > s.tasks[s.task_id].priority { return destination }
	return s.current
}
fn (mut s Scheduler) wait_task() int { s.tasks[s.task_id].state |= wait_bit; return s.task_id }
fn (mut s Scheduler) hold_task() int {
	s.hold_count++
	s.tasks[s.task_id].state |= hold_bit
	return s.tasks[s.task_id].link
}
fn (mut s Scheduler) run_task(mut packet int) int {
	if s.task_id == idle {
		s.v2--
		if s.v2 == 0 { return s.hold_task() }
		if (s.v1 & 1) == 0 { s.v1 = (s.v1 >> 1) & 32767; return s.release_task(device_a) }
		s.v1 = ((s.v1 >> 1) & 32767) ^ 0xd008
		return s.release_task(device_b)
	}
	if s.task_id == work {
		if packet == 0 { return s.wait_task() }
		s.v1 = i64(handler_a + handler_b) - s.v1
		s.packets[packet].id = int(s.v1)
		s.packets[packet].a1 = 0
		for index in 0 .. 4 {
			s.v2++
			if s.v2 > 26 { s.v2 = 1 }
			s.packets[packet].a2[index] = 64 + int(s.v2)
		}
		return s.queue_packet(packet)
	}
	if s.task_id == handler_a || s.task_id == handler_b {
		if packet != 0 {
			if s.packets[packet].kind == k_work { s.v1 = i64(s.append_packet(packet, int(s.v1))) }
			else { s.v2 = i64(s.append_packet(packet, int(s.v2))) }
		}
		if s.v1 != 0 {
			work_packet := int(s.v1)
			count := s.packets[work_packet].a1
			if count > 3 { s.v1 = s.packets[work_packet].link; return s.queue_packet(work_packet) }
			if s.v2 != 0 {
				device_packet := int(s.v2)
				s.v2 = s.packets[device_packet].link
				s.packets[device_packet].a1 = s.packets[work_packet].a2[count]
				s.packets[work_packet].a1 = count + 1
				return s.queue_packet(device_packet)
			}
		}
		return s.wait_task()
	}
	if packet == 0 {
		if s.v1 == 0 { return s.wait_task() }
		packet = int(s.v1)
		s.v1 = 0
		return s.queue_packet(packet)
	}
	s.v1 = packet
	return s.hold_task()
}
fn (mut s Scheduler) schedule() bool {
	for s.current != 0 {
		mut packet := 0
		task_id := s.current
		if s.tasks[task_id].state == wait_pkt {
			packet = s.tasks[task_id].queue
			s.tasks[task_id].queue = s.packets[packet].link
			s.tasks[task_id].state = if s.tasks[task_id].queue == 0 { run_state } else { run_pkt }
		}
		state := s.tasks[task_id].state
		if state == run_state || state == run_pkt {
			s.task_id = task_id
			s.v1 = s.tasks[task_id].v1
			s.v2 = s.tasks[task_id].v2
			s.current = s.run_task(mut packet)
			s.tasks[task_id].v1 = s.v1
			s.tasks[task_id].v2 = s.v2
		} else if state == wait_state || state == hold_state || state == hold_pkt || state == hold_wait || state == hold_wait_pkt {
			s.current = s.tasks[task_id].link
		} else { return false }
	}
	return true
}

@[export: 'richards_benchmark']
pub fn richards_benchmark(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	iterations := unsafe { input[0] }
	if iterations < 1 || iterations > max_iterations { return -1 }
	mut s := Scheduler{}
	mut work_head := s.make_packet(0, 0, k_work)
	work_head = s.make_packet(work_head, 0, k_work)
	s.make_task(idle, 0, 0, run_state, 1, iterations)
	s.make_task(work, 1000, work_head, wait_pkt, handler_a, 0)
	mut handler_a_head := s.make_packet(0, device_a, k_dev)
	handler_a_head = s.make_packet(handler_a_head, device_a, k_dev)
	handler_a_head = s.make_packet(handler_a_head, device_a, k_dev)
	s.make_task(handler_a, 2000, handler_a_head, wait_pkt, 0, 0)
	mut handler_b_head := s.make_packet(0, device_b, k_dev)
	handler_b_head = s.make_packet(handler_b_head, device_b, k_dev)
	handler_b_head = s.make_packet(handler_b_head, device_b, k_dev)
	s.make_task(handler_b, 3000, handler_b_head, wait_pkt, 0, 0)
	s.make_task(device_a, 4000, 0, wait_state, 0, 0)
	s.make_task(device_b, 5000, 0, wait_state, 0, 0)
	s.current = s.task_list
	if !s.schedule() { return -1 }
	return i64(s.packet_count) * i64(2147483648) + i64(s.hold_count)
}
