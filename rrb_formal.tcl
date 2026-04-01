clear -all

analyze -sv12  round_robin_arbiter.sv 

analyze -sv12 rrb_fv_tb.sv \ rrb_bind.sv

check_cov -init -type all -model {branch toggle statement} -toggle_ports_only

elaborate -top rrarb_p

clock clk

reset -expression {rst == 1'b1}

prove -all

check_cov -measure -type {coi stimuli proof bound} -time_limit 60s -bg
