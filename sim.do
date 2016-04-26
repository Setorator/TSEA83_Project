force -freeze sim:/cpu/clk 1 0, 0 {10 ns} -r 20
force -freeze sim:/cpu/rst 0 0
force -freeze sim:/cpu/intr 0 0
force -freeze sim:/cpu/intr2 0 0
force -freeze sim:/cpu/joystick_poss 2'h0 0
force -freeze sim:/cpu/joystick_poss 2'h1 6000
force -freeze sim:/cpu/joystick_poss 2'h2 10000
force -freeze sim:/cpu/intr2 1 500
force -freeze sim:/cpu/intr2 0 602
force -freeze sim:/cpu/intr_code 4'h0 0
