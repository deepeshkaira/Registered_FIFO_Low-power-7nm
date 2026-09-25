# SAIF activity

Questa Power Aware simulation writes the activity file here:

```text
registered_sync_fifo.saif
```

The generated SAIF is ignored by Git because it is derived simulation data. PrimeTime annotates it with this RTL simulation scope removed:

```tcl
read_saif -strip_path registered_sync_fifo_tb/dut $saif_file
```
