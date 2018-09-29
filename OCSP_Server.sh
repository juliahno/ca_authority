#!/bin/bash
openssl ocsp -index ca-authority/conf/index -port 8888 -rsigner ca-authority/OCSP/ocsp.cer -rkey ca-authority/OCSP/ocsp.key -CA ca-authority/cacerts/cacert.pem -text -out ca-authority/OCSP/log/log.txt
