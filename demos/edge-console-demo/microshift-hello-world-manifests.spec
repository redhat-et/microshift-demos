
%global manifestStore /usr/lib/microshift/manifests
Name: microshift-hello-world-manifests
Version: 1.0.0
Release: 1
Summary: Application specific manifests
License: Apache License 2.0
Source0: microshift-hello-world-manifests-1.0.0-1-manifests.tar.bz2

%description
This package provides a manifests for the deployed application in MicroShift.

%install
mkdir -p %{buildroot}%{manifestStore}
cd %{buildroot}%{manifestStore}
tar xfjv %{SOURCE0}

%files
%dir "%{manifestStore}"
"%{manifestStore}/kustomization.yaml"
"%{manifestStore}/microweb-mdns.yaml"
"%{manifestStore}/microweb-ns.yaml"
"%{manifestStore}/microweb-service.yaml"
"%{manifestStore}/microweb.yaml"

%changelog
* Thu Oct 27 2022 Miguel Angel Ajo <majopela@redhat.com> . 1.0.0-1
First version of the manifests package
