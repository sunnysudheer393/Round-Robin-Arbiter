# Round-Robin Arbiter — Formal Verification with SVA & JasperGold

A parameterized N-requester **Round-Robin Arbiter** implemented in SystemVerilog, formally verified using **SystemVerilog Assertions (SVA)** and **Cadence JasperGold**.

---

## Overview

A round-robin arbiter grants shared-resource access to multiple requesters in a fair, cyclic order. This project provides:

- A synthesizable RTL implementation of a round-robin arbiter (`rrarb_p`)
- A formal verification testbench with SVA assumptions and assertions (`rrb_fv_tb`)
- A bind file for non-intrusive assertion attachment (`rrb_bind`)
- A JasperGold TCL script to run the full formal flow (`rrb_formal.tcl`)

---

## Repository Structure

```
Round-Robin-Arbiter/
├── round_robin_arbiter.svh   # RTL: parameterized round-robin arbiter (rrarb_p)
├── rrb_fv_tb.svh             # Formal verification testbench with SVA properties
├── rrb_bind.svh              # Bind file to attach the FV testbench to the DUT
└── rrb_formal.tcl            # JasperGold TCL script for the formal flow
```

---

## Design Description

### Module: `rrarb_p`

```
module rrarb_p #(parameter int N = 4) (
    input  logic [N-1:0] req,
    input  logic         clk,
    input  logic         rst,
    output logic [N-1:0] gnt
);
```

**Parameters**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N`       | `4`     | Number of requesters |

**Ports**

| Port  | Direction | Width   | Description                    |
|-------|-----------|---------|--------------------------------|
| `req` | Input     | `[N-1:0]` | Request signals from clients |
| `clk` | Input     | 1-bit   | Clock                          |
| `rst` | Input     | 1-bit   | Synchronous active-high reset  |
| `gnt` | Output    | `[N-1:0]` | One-hot grant signal         |

### How It Works

The arbiter maintains a **priority counter** (`cnt`) that rotates after each grant. On each clock cycle:

1. The `req` bus is **right-rotated** by `cnt` positions so the last-granted requester moves to the lowest priority.
2. A **lowest-set-bit** trick (`req_shift & -req_shift`) selects the highest-priority active request.
3. The grant is **left-rotated** back by `cnt` positions to restore the original indexing.
4. `cnt` advances to the index just after the granted requester, implementing the cyclic round-robin policy.

> A commented-out `case`-based implementation (for fixed N=4) is also included in the file for reference alongside the generalized parameterized version.

---

## Formal Verification

### Testbench: `rrb_fv_tb`

The FV testbench uses **symbolic variables** (`symb_req`, `symb_req1`, `symb_req2`) to represent any arbitrary requester indices, enabling exhaustive proof over all possible inputs.

#### Assumptions

| Assumption | Description |
|------------|-------------|
| `$stable(symb_req)` | The symbolic index stays constant throughout the proof |
| `req[symb_req] && !gnt[symb_req] \|-> req[symb_req] s_until_with gnt[symb_req]` | A requester holds its request high until it is granted |
| `$stable(symb_req1) && $stable(symb_req2) && (symb_req1 != symb_req2)` | Two symbolic indices are stable and distinct |

#### Assertions

| Property | Description |
|----------|-------------|
| `$rose(rst) \|-> gnt == 4'b0000` | After reset, no grant is active |
| `req[symb_req] \|-> s_eventually gnt[symb_req]` | **Liveness**: every request is eventually granted |
| `$onehot0(gnt)` | **Mutual exclusion**: at most one grant is asserted at a time |
| `gnt[symb_req] \|-> req[symb_req]` | A grant can only be issued to an active request |
| `!(|req) \|-> !(|gnt)` | No requests means no grants |
| `(|req) \|-> (|gnt)` | At least one request means a grant is issued |
| `gnt[symb_req1] \|=> !gnt[symb_req1] s_until_with gnt[symb_req2]` | **Fairness**: after granting req1, req2 is served before req1 is re-granted |

#### Cover Properties

| Cover | Description |
|-------|-------------|
| `$countones(req) > 1` | Multiple simultaneous requests occur |
| `gnt[0] ##1 gnt[1] ##1 gnt[2] ##1 gnt[3]` | Back-to-back grants cycling through all four requesters |

---

## Running the Formal Flow (JasperGold)

### Prerequisites

- **Cadence JasperGold** (Formal Property Verification app)
- SystemVerilog-2012 support

### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/sunnysudheer393/Round-Robin-Arbiter.git
   cd Round-Robin-Arbiter
   ```

2. Rename `.svh` files to `.sv` (or update the TCL script paths):
   ```bash
   cp round_robin_arbiter.svh round_robin_arbiter.sv
   cp rrb_fv_tb.svh rrb_fv_tb.sv
   cp rrb_bind.svh rrb_bind.sv
   ```

3. Launch JasperGold and source the TCL script:
   ```tcl
   source rrb_formal.tcl
   ```

### What the TCL Script Does

```tcl
clear -all
analyze -sv12 round_robin_arbiter.sv
analyze -sv12 rrb_fv_tb.sv rrb_bind.sv
check_cov -init -type all -model {branch toggle statement} -toggle_ports_only
elaborate -top rrarb_p
clock clk
reset -expression {rst == 1'b1}
prove -all
check_cov -measure -type {coi stimuli proof bound} -time_limit 60s -bg
```

The script analyzes all design and verification files, elaborates the top-level module, configures the clock and reset, runs the proof engine on all properties, and measures formal coverage.

---

## Key Concepts

**Round-Robin Arbitration** — A scheduling policy that cycles through requesters in order, preventing starvation by guaranteeing each requester a turn.

**SystemVerilog Assertions (SVA)** — A specification language embedded in SystemVerilog used to describe temporal properties of hardware designs.

**Formal Property Verification (FPV)** — A mathematical technique that exhaustively proves (or disproves) that design properties hold for all possible input sequences, without requiring simulation vectors.

**Bind Files** — A SystemVerilog mechanism for attaching a verification module to a DUT without modifying the DUT source, keeping RTL and verification code cleanly separated.

**Symbolic Variables** — In FPV, free variables that the tool treats as representing any possible value, allowing a single assertion to cover all requester indices simultaneously.

---

## Language & Tools

| Component | Technology |
|-----------|------------|
| RTL Design | SystemVerilog (IEEE 1800-2012) |
| Verification | SystemVerilog Assertions (SVA) |
| Formal Tool | Cadence JasperGold |
| Script | Tcl |

---

## License

This project is open source. See the repository for details.
