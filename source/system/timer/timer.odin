package timer

import sdl "shared:odin-sdl2"

Timer :: struct {
	start_ticks: u32,
	paused_ticks: u32,
	started: bool,
	paused: bool,
}

timer_start :: proc (using t: ^Timer) {
	started = true;
	paused = false;
	start_ticks = sdl.get_ticks();
	paused_ticks = 0;
}

timer_stop :: proc (using t: ^Timer) {
	started = false;
	paused = false;
	start_ticks = 0;
	paused_ticks = 0;
}

timer_pause :: proc (using t: ^Timer) {
	if (started && !paused) {
		paused = true;
		paused_ticks = sdl.get_ticks() - start_ticks;
		start_ticks = 0;
	}
}

timer_unpause :: proc (using t: ^Timer) {
	if (started && paused) {
		paused = false;
		start_ticks = sdl.get_ticks() - paused_ticks;
		paused_ticks = 0;
	}
}

timer_get_ticks :: proc (using t: ^Timer) -> (time: u32) {
	if (started) {
		if (paused) {
			time = paused_ticks;
		}
		else {
			time = sdl.get_ticks() - start_ticks;
		}
	}
	return time;
}