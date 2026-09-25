# PrimeTime netlist parsing issue

## Symptom

PrimeTime stops during `read_verilog` with messages of this form:

```text
Error: Width of port DATA1 (23) is inconsistent with other instances (1) (SVR-15)
Error: Width of port DATA2 (23) is inconsistent with other instances (1) (SVR-15)
Error: Width of port Z (23) is inconsistent with other instances (1) (SVR-15)
```

The later `Cannot find design 'registered_sync_fifo'` and `Current design is not defined` messages are consequences of the failed netlist read.

## Why SAIF is not the cause

The error is emitted while PrimeTime parses structural Verilog. `read_saif` has not executed at this point. Unknown activity values can affect annotation coverage and power accuracy, but they cannot change Verilog port widths.

## Next commands

```bash
nl -ba netlist/registered_sync_fifo_gated.v | sed -n '125,165p'
grep -nE "\.(DATA1|DATA2|Z)[[:space:]]*\(" netlist/registered_sync_fifo_gated.v
grep -nE "^[[:space:]]*module[[:space:]]" netlist/registered_sync_fifo_gated.v
grep -niE "unresolved|black box|generic|unmapped|level.shifter|isolation" logs/dc_registered_sync_fifo.log
grep -RniE "unresolved|black box|generic|unmapped|level.shifter|isolation" reports/synthesis
```

The cell name around the reported lines will determine whether the correction requires physical power-cell mapping, bit-level expansion, an additional Verilog model, or use of the DC DDC database for the immediate PrimeTime experiment.
