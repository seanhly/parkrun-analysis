#for i in $(seq 553 595); do rm $i.html; done
#exit
#for i in $(seq 423 480); do rm $i.html; done
#for row in $(cat index.txt); do
for row in $(cat index.txt); do
	out=${row#*s/}
	out="${out%/}.html"
	if [ ! -e "$out" ]; then
		curl "$row" \
		  --compressed \
		  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:115.0) Gecko/20100101 Firefox/115.24.0' \
		  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' \
		  -H 'Accept-Language: en-US,en;q=0.5' \
		  -H 'Accept-Encoding: gzip, deflate, br' \
		  -H 'DNT: 1' \
		  -H 'Connection: keep-alive' \
		  -H 'Cookie: psc=%7B%22categories%22%3A%5B%22necessary%22%2C%22personalisation%22%2C%22analytics%22%5D%2C%22revision%22%3A1%2C%22data%22%3Anull%2C%22consentTimestamp%22%3A%222025-10-03T16%3A37%3A25.351Z%22%2C%22consentId%22%3A%22cd3ce520-8b73-4e48-8932-cbe3a8c4fcab%22%2C%22services%22%3A%7B%22necessary%22%3A%5B%5D%2C%22personalisation%22%3A%5B%5D%2C%22analytics%22%3A%5B%22ga%22%2C%22mapbox%22%2C%22youtube%22%2C%22twitter%22%5D%7D%2C%22languageCode%22%3A%22en%22%2C%22lastConsentTimestamp%22%3A%222025-10-03T16%3A37%3A25.351Z%22%2C%22expirationTime%22%3A1775234245351%7D; im_youtube=1; aws-waf-token=9730b205-f4c4-4575-a93a-471855be313e:CgoAhaBjTDapAQAA:eeOyY9YnCrFkWgjF/pKX3jpFusovzw3AGD7HBCZXo04fLD99rtn2oZiZmiC0+kDFswqJemhOB5uXbDEokUFxzqqHtB5Uf5aFXZx3jB0oHstV/v6z5PAss6Uiau8uuOTs05xyrEdaFRTYHTMwNzTMcqp8gjTf/MtBTxknrsmAyOSgE2WZMSpdxuP3X4hVSgwcWXW8bNLUumOAmk2sPALUQBKjy5cJxg==' \
		  -H 'Upgrade-Insecure-Requests: 1' \
		  -H 'Sec-Fetch-Dest: document' \
		  -H 'Sec-Fetch-Mode: navigate' \
		  -H 'Sec-Fetch-Site: cross-site' \
		  -H 'TE: trailers' > "$out"
		sleep 2.1s
	fi
done
