#!/bin/bash
openssl ocsp -index jiacerts-ca/conf/index -port 8888 -rsigner ocsp.cer -rkey ocsp.key -CA cacert.pem -text -out log.txt
