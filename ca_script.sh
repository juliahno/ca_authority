#!/bin/bash
if [ $USER != "root" ]
then
    echo -e "\n===== ESTE SCRIPT DEVE SER EXECUTADO PELO USUARIO ROOT =====\n"
    exit
fi

while true 
do
    clear

    echo "================= CA AUTHORITY ================"
    echo "[1] Criar Estrutura da CA"
    echo "[2] Criar Certificado do Servidor OCSP"
    echo "[3] Criar Requisicao e Chave do Cliente"
    echo "[4] Assinar Certificado do Cliente"
    echo "[5] Revogar Certificado do Cliente"
    echo "[6] Consultar OCSP"
    echo "[7] Gerar Lista de Certificados Revogados"
    echo "[8] Visualizar Certificado (CRT/CER)"
    echo "[9] Visualizar Requisicao (CSR)"
    echo "[10] Visualizar Chave Privada (KEY)"
    echo "[11] Visualizar CRL"
    echo "-----------------------------------------------"
    echo "[0] Sair"
    echo "==============================================="
    echo -n "Opcao: "
    read OPCAO

    case $OPCAO in
	1)	
		if [ ! -d "ca-authority" ] 
		then
			mkdir -p ca-authority/{conf,private,public,signed-keys,CRL} reqs 
			cd ca-authority
			echo "01" > conf/serial
			touch conf/index
			cp ../openssl.cnf conf/

			echo "GERANDO CHAVE PRIVADA..."
			openssl genrsa -des3 -out private/root.key 2048
			echo ""

			echo "GERANDO CERTIFICADO DA CA..."
			openssl req -x509 -new -nodes -config conf/openssl.cnf -days 1825 -key private/root.key -out public/root.crt -extensions v3_OCSP
			echo ""

			chmod 400 private
			cd ..
			cat ca-authority/private/root.key ca-authority/public/root.crt > cacert.pem
		else 
			echo "DIRETORIO 'ca-authority' JA EXISTE"
		fi
		;;
	2)
		openssl genrsa -des3 -out ocsp.key 2048
		openssl req -new -key ocsp.key -nodes -out ocsp.csr
		openssl ca -batch -config ca-authority/conf/openssl.cnf -in ocsp.csr -out ocsp.cer -extensions v3_OCSP
		rm ocsp.csr
		;;
	3)
		echo -n "Nome de Arquivo para o Cliente: "
		read CLIENTE

		echo "GERANDO CHAVE PRIVADA..."
		openssl genrsa -des3 -out $CLIENTE.key 2048
		echo ""

		echo "GERANDO CERTIFICADO DO CLIENTE..."
		openssl req -new -key $CLIENTE.key -nodes -out $CLIENTE.csr 
		echo ""

		mv $CLIENTE.key $CLIENTE.csr ./reqs
		echo "Chave Privada e CSR Criados no Diretorio 'reqs'"
		;;
	4)
		echo -n "Nome do Arquivo Gerado para o Cliente: "
		read -e CLIENTE

		openssl ca -batch -config ca-authority/conf/openssl.cnf -in reqs/$CLIENTE.csr -out reqs/$CLIENTE.cer -extensions v3_OCSP
		#openssl pkcs12 -export -in reqs/$CLIENTE.cer -inkey reqs/$CLIENTE.key -out reqs/$CLIENTE.p12 
		#openssl pkcs12 -in reqs/$CLIENTE.p12 -nodes -out reqs/$CLIENTE.pem
		;;
	5)
		echo -n "Serial do Certificado: "
		read -e SERIAL

		openssl ca -config ca-authority/conf/openssl.cnf -revoke ca-authority/signed-keys/$SERIAL.pem
		;;
	6)
		echo -n "Serial do Certificado: "
		read -e SERIAL

		openssl ocsp -CAfile cacert.pem -issuer cacert.pem -cert ca-authority/signed-keys/$SERIAL.pem -url http://auth-certs.com:8888 -resp_text
		;;
	7)
		openssl ca -config ca-authority/conf/openssl.cnf -gencrl -out ./ca-authority/CRL/ca-authority-crl.crl
		;;
	8)
		read -e -p "Certificado: " CERTIFICADO
		openssl x509 -in $CERTIFICADO -noout -text
		;;
	9) 
		read -e -p "Requisicao: " REQUISICAO
		openssl req -text -noout -verify -in $REQUISICAO
		;;    
	10) 
		read -e -p "Chave Privada: " CH_PRIVADA
		openssl rsa -in $CH_PRIVADA -check
		;;
	11)
		openssl crl -text -noout -in ca-authority/CRL/ca-authority-crl.crl
		;;
	0) 
		exit
		;;
	*) 
		echo "Opcao Invalida"
		;;
	esac
	read -p "(TECLE ENTER PARA CONTINUAR)"
done