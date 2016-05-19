force -freeze sim:/cpu/clk 1 0, 0 {10 ns} -r 20
force -freeze sim:/cpu/rst 0 0
force -freeze sim:/cpu/intr 0 0
force -freeze sim:/cpu/intr2 0 0
force -freeze sim:/cpu/intr3 0 0
force -freeze sim:/cpu/joystick_pos 2'h0 0
force -freeze sim:/cpu/joystick_pos 2'h1 6000
force -freeze sim:/cpu/joystick_pos 2'h2 10000
force -freeze sim:/cpu/intr 1 500000
force -freeze sim:/cpu/intr 0 600000
force -freeze sim:/cpu/intr3 1 1000000
force -freeze sim:/cpu/intr3 0 2000000
force -freeze sim:/cpu/intr_code 4'h0 0
