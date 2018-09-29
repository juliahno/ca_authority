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
			echo "CRIANDO ESTRUTURA DE DIRETORIOS..."
			mkdir -p ca-authority/{conf,private,public,cacerts,signed-keys,CRL,OCSP/log,reqs}
			echo ""

			echo "01" > ca-authority/conf/serial
			touch ca-authority/conf/index
			cp openssl.cnf ca-authority/conf

			echo "GERANDO CHAVE PRIVADA..."
			openssl genrsa -des3 -out ca-authority/private/root.key 2048
			echo ""

			echo "GERANDO CERTIFICADO DA AC..."
			openssl req -x509 -new -nodes -config ca-authority/conf/openssl.cnf -days 1825 -key ca-authority/private/root.key -out ca-authority/public/root.crt -extensions v3_OCSP
			echo ""

			cat ca-authority/private/root.key ca-authority/public/root.crt > ca-authority/cacerts/cacert.pem
		else 
			echo "DIRETORIO 'ca-authority' JA EXISTE"
		fi
		;;
	2)
		echo "GERANDO CSR OCSP..."
		openssl genrsa -des3 -out ca-authority/OCSP/ocsp.key 2048
		openssl req -new -key ca-authority/OCSP/ocsp.key -nodes -out ca-authority/OCSP/ocsp.csr
		echo ""

		echo "GERANDO CERTIFICADO OCSP..."
		openssl ca -batch -config ca-authority/conf/openssl.cnf -in ca-authority/OCSP/ocsp.csr -out ca-authority/OCSP/ocsp.cer -extensions v3_OCSP
		;;
	3)
		echo -n "Nome de Arquivo para o Cliente: "
		read CLIENTE

		echo "GERANDO CHAVE PRIVADA..."
		openssl genrsa -des3 -out ca-authority/reqs/$CLIENTE.key 2048
		echo ""

		echo "GERANDO CSR DO CLIENTE..."
		openssl req -new -key ca-authority/reqs/$CLIENTE.key -nodes -out ca-authority/reqs/$CLIENTE.csr 
		echo ""

		echo "Chave Privada e CSR Criados no Diretorio 'reqs'"
		;;
	4)
		echo -n "Nome do Arquivo Gerado para o Cliente: "
		read CLIENTE

		openssl ca -batch -config ca-authority/conf/openssl.cnf -in ca-authority/reqs/$CLIENTE.csr -out ca-authority/reqs/$CLIENTE.cer -extensions v3_OCSP
		;;
	5)
		echo -n "Serial do Certificado: "
		read -e SERIAL

		openssl ca -config ca-authority/conf/openssl.cnf -revoke ca-authority/signed-keys/$SERIAL.pem
		;;
	6)
		echo -n "Serial do Certificado: "
		read -e SERIAL

		openssl ocsp -CAfile ca-authority/cacerts/cacert.pem -issuer ca-authority/cacerts/cacert.pem -cert ca-authority/signed-keys/$SERIAL.pem -url http://localhost:8888 -resp_text
		;;
	7)
		openssl ca -config ca-authority/conf/openssl.cnf -gencrl -out ca-authority/CRL/ca-authority.crl
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
		openssl crl -text -noout -in ca-authority/CRL/ca-authority.crl
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