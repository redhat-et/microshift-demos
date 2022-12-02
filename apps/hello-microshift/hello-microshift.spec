Name:           microshift-hello-microshift-app
Version:        0.0.1
Release:        1%{?dist}
Summary:        Manifests of the "Hello, MicroShift!" app

License:        ASL 2.0
URL:            https://github.com/redhat-et/microshift-demos/tree/main/apps/hello-microshift
Source0:        https://github.com/redhat-et/microshift-demos/archive/refs/tags/hello-microshift-v%{version}.tar.gz
BuildArch:      noarch

%description
Installs the manifests of the "Hello, MicroShift!" app into MicroShift's
auto-manifest folder.


%global tardir microshift-demos-hello-microshift-v%{version}
%global source %{_builddir}/%{tardir}/apps/hello-microshift
%global manifestdir /etc/microshift/manifests

%prep
%setup -q -n %{tardir}

%build

%install
mkdir -p %{buildroot}/%{manifestdir}
install -m 0644 %{source}/deployment.yaml %{buildroot}/%{manifestdir}/deployment.yaml
install -m 0644 %{source}/kustomization.yaml %{buildroot}/%{manifestdir}/kustomization.yaml
install -m 0644 %{source}/namespace.yaml %{buildroot}/%{manifestdir}/namespace.yaml
install -m 0644 %{source}/route.yaml %{buildroot}/%{manifestdir}/route.yaml
install -m 0644 %{source}/service.yaml %{buildroot}/%{manifestdir}/service.yaml

%files
%dir %{manifestdir}
%config %{manifestdir}/deployment.yaml
%config %{manifestdir}/kustomization.yaml
%config %{manifestdir}/namespace.yaml
%config %{manifestdir}/route.yaml
%config %{manifestdir}/service.yaml

%changelog
* Fri Dec  2 2022 Frank A. Zdarsky <fzdarsky@redhat.com> - 0.0.1-1
- First package
