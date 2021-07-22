FROM centos
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/bin/kubectl
RUN curl -L -o oc.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz && \
    tar xzvf oc.tar.gz && \
    chmod +x ./oc; mv oc /usr/local/bin
COPY acm*sh /
COPY run.sh /run.sh
ENTRYPOINT ["/run.sh"]
