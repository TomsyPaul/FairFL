#! /bin/bash
for i in `cat hostipsall | tail -n+4`; do ssh tomsy@$i mkdir mydfl; done
