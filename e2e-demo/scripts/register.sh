sudo tee /etc/rhc/config.toml > /dev/null <<EOF
# yggdrasil global configuration settings
broker = ["wss://connect.cloud.stage.redhat.com:443"]
cert-file = "/etc/pki/consumer/cert.pem"
key-file = "/etc/pki/consumer/key.pem"
log-level = "trace"
data-host = "cert.cloud.stage.redhat.com"
topic-prefix = "redhat/insights"
EOF

sudo tee /etc/insights-client/insights-client.conf > /dev/null <<EOF
[insights-client]
auto_config=False
username=insights-qa
password=redhatqa
legacy_upload=False
base_url=cert.cloud.stage.redhat.com/api
cert_verify=True
proxy=http://squid.corp.redhat.com:3128
EOF

sudo subscription-manager register < /dev/tty
sudo systemctl enable --now rhcd

# verify rhcd started
sudo systemctl status rhcd

sudo insights-client --register

