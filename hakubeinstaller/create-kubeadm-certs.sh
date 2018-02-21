# default output_dir
output_dir=$(realpath assets/pki)

# change into default directory
cd ${output_dir}

cat > ${output_dir}/csr.json <<EOL
{
   "CN": "kubernetes",
   "key": {
       "algo": "rsa",
       "size": 2048
   }
}
EOL
# create general ca, and ca for front-proxy
cfssl gencert -initca csr.json | cfssljson -bare ca
cfssl gencert -initca csr.json | cfssljson -bare front-proxy-ca

cat > ${output_dir}/ca-config.json <<EOL
{
	"signing": {
		"default": {
			"expiry": "8760h"
		},
		"profiles": {
			"kubernetes": {
				"usages": ["signing", "key encipherment", "server auth", "client auth"],
				"expiry": "8760h"
			}
		}
	}
}
EOL

cat > ${output_dir}/front-proxy-client.json <<EOL
{
   "CN": "front-proxy-client",
   "key": {
       "algo": "rsa",
       "size": 2048
   }
}
EOL

# creates front proxy client cert
cfssl gencert \
    -ca=front-proxy-ca.pem \
    -ca-key=front-proxy-ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    front-proxy-client.json | cfssljson -bare front-proxy-client


# create service account key pair
openssl req  -nodes -new -x509  -keyout sa.key -out sa.pub -subj "/AU=US"
openssl rsa -in sa.key -pubout -out sa.pub
